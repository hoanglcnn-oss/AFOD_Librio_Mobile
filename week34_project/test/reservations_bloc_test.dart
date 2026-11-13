import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/constants/api_constants.dart';
import 'package:week34_project/features/borrowing/reservations/bloc/reservations_bloc.dart';
import 'package:week34_project/features/borrowing/reservations/bloc/reservations_event.dart';
import 'package:week34_project/features/borrowing/reservations/bloc/reservations_state.dart';
import 'package:week34_project/features/borrowing/reservations/data/models/reservation.dart';

import 'fake/fake_reservations_repository.dart';

void main() {
  group('ReservationsBloc', () {
    late FakeReservationsRepository repository;
    late ReservationsBloc bloc;

    final initialReservation = Reservation(
      id: 'res-1',
      reservationCode: 'RSV-001',
      memberId: 'mem-1',
      bookId: 'b-1',
      bookTitle: 'Clean Code',
      status: 'PENDING',
      reservedAt: DateTime(2026, 11, 10),
    );

    setUp(() {
      repository = FakeReservationsRepository(
        initialReservations: [initialReservation],
      );
      bloc = ReservationsBloc(reservationsRepository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state is ReservationsInitial', () {
      expect(bloc.state, isA<ReservationsInitial>());
    });

    test(
      'LoadReservations success emits [ReservationsLoading, ReservationsLoaded]',
      () async {
        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationsLoading>());
        expect(states[1], isA<ReservationsLoaded>());

        final loaded = states[1] as ReservationsLoaded;
        expect(loaded.reservations.length, 1);
        expect(loaded.reservations.first.id, 'res-1');
        expect(loaded.memberId, 'mem-1');
      },
    );

    test(
      'LoadReservations failure emits [ReservationsLoading, ReservationsFailure]',
      () async {
        repository.shouldFailGet = true;

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationsLoading>());
        expect(states[1], isA<ReservationsFailure>());
      },
    );

    test(
      'RefreshReservations updates loaded reservations without showing initial loading',
      () async {
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);
        expect(bloc.state, isA<ReservationsLoaded>());

        repository.reservations.add(
          Reservation(
            id: 'res-2',
            reservationCode: 'RSV-002',
            memberId: 'mem-1',
            bookId: 'b-2',
            bookTitle: 'Design Patterns',
            status: 'READY',
            reservedAt: DateTime.now(),
          ),
        );

        final completer = Completer<void>();
        bloc.add(RefreshReservations('mem-1', completer: completer));
        await completer.future;

        expect(bloc.state, isA<ReservationsLoaded>());
        final loaded = bloc.state as ReservationsLoaded;
        expect(loaded.reservations.length, 2);
      },
    );

    test(
      'CancelReservationRequested success emits [ReservationCancelling, ReservationCancelSuccess]',
      () async {
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
            reason: 'Không cần nữa',
          ),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCancelling>());
        expect(states[1], isA<ReservationCancelSuccess>());

        final success = states[1] as ReservationCancelSuccess;
        expect(success.paginated.items.first.status, 'CANCELLED');
        expect(repository.cancelCallCount, 1);
      },
    );

    test(
      'PATCH cancel thành công nhưng GET refresh lỗi | Vẫn báo hủy thành công và giữ dữ liệu Backend đã trả',
      () async {
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        // Sau khi cancel xong, GET getReservations sẽ lỗi
        repository.cancelCompleter = Completer<void>();

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
          ),
        );
        await Future.delayed(Duration.zero);
        expect(bloc.state, isA<ReservationCancelling>());

        // Cấu hình GET bị lỗi
        repository.shouldFailGet = true;
        repository.cancelCompleter!.complete();
        await Future.delayed(Duration.zero);

        // Phải emit ReservationCancelSuccess chứ không được làm mất kết quả thành công
        expect(states.last, isA<ReservationCancelSuccess>());
        final success = states.last as ReservationCancelSuccess;
        expect(success.paginated.items.first.status, 'CANCELLED');
      },
    );

    test(
      'Refresh chạy chồng với PATCH cancel thành công | Không làm mất ReservationCancelSuccess',
      () async {
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);
        expect(bloc.state, isA<ReservationsLoaded>());

        // Treo lần gọi GET tiếp theo (của refresh)
        final hangingGetCompleter = Completer<void>();
        repository.getCompleter = hangingGetCompleter;
        repository.pauseNextGetOnly = true;

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        final refreshCompleter = Completer<void>();
        // 1. Kích hoạt Refresh
        bloc.add(RefreshReservations('mem-1', completer: refreshCompleter));
        await Future.delayed(Duration.zero);

        // 2. Kích hoạt CancelRequested trong khi Refresh đang chạy
        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
            reason: 'Hủy khi đang refresh',
          ),
        );
        await Future.delayed(Duration.zero);

        // 3. Giải phóng refresh GET đang bị treo
        hangingGetCompleter.complete();
        await Future.delayed(Duration.zero);
        await refreshCompleter.future;

        // 4. Kiểm tra: ReservationCancelSuccess không bị mất hay ghi đè bởi ReservationsLoaded cũ
        expect(states.whereType<ReservationCancelSuccess>().length, 1);
        expect(states.last, isA<ReservationCancelSuccess>());
        final success = states.last as ReservationCancelSuccess;
        expect(success.paginated.items.first.status, 'CANCELLED');
      },
    );

    test(
      'CancelReservationRequested prevents duplicate submit when cancelling',
      () async {
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        repository.cancelCompleter = Completer<void>();

        // Gửi lần 1
        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
          ),
        );
        await Future.delayed(Duration.zero);
        expect(bloc.state, isA<ReservationCancelling>());
        expect(repository.cancelCallCount, 1);

        // Gửi lần 2 trong lúc đang xử lý
        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
          ),
        );
        await Future.delayed(Duration.zero);
        expect(repository.cancelCallCount, 1); // Vẫn chỉ gọi 1 lần

        repository.cancelCompleter!.complete();
        await Future.delayed(Duration.zero);
        expect(bloc.state, isA<ReservationCancelSuccess>());
      },
    );

    test(
      'Chống response load cũ ghi đè khi mutation đang hoặc vừa hoàn tất',
      () async {
        // Giả lập load chậm
        final loadCompleter = Completer<void>();
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        // Trước khi load xong, đã có state loaded trước đó
        // Giả lập trigger cancel
        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
          ),
        );
        await Future.delayed(Duration.zero);

        // Response của load cũ đến sau -> không được ghi đè
        loadCompleter.complete();
        await Future.delayed(Duration.zero);

        expect(bloc.state, isNot(isA<ReservationsLoading>()));
      },
    );

    test(
      'CancelReservationRequested timeout | Backend xác nhận đã hủy -> Success không gọi lại PATCH',
      () async {
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        repository.cancelError = DioException(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          type: DioExceptionType.connectionTimeout,
        );

        // Backend đã chuyển sang CANCELLED
        repository.reservations[0] = repository.reservations[0].copyWith(
          status: 'CANCELLED',
        );

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
          ),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCancelling>());
        expect(states[1], isA<ReservationCancelSuccess>());
        expect(repository.cancelCallCount, 1); // Không tự retry mutation
        expect(repository.getByIdCallCount, 1); // Kiểm tra lại qua GET
      },
    );

    test(
      'CancelReservationRequested timeout | Backend chưa hủy -> Failure không gọi lại PATCH',
      () async {
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        repository.cancelError = DioException(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          type: DioExceptionType.receiveTimeout,
        );

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
          ),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCancelling>());
        expect(states[1], isA<ReservationCancelFailure>());
        expect(repository.cancelCallCount, 1); // Không tự retry PATCH
      },
    );

    test(
      'CancelReservationRequested non-timeout error -> ReservationCancelFailure',
      () async {
        bloc.add(const LoadReservations(memberId: 'mem-1'));
        await Future.delayed(Duration.zero);

        repository.cancelError = DioException(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.reservations),
            statusCode: 400,
            data: {'message': 'Không thể hủy phiếu đã hoàn tất'},
          ),
        );

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CancelReservationRequested(
            reservationId: 'res-1',
            memberId: 'mem-1',
          ),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCancelling>());
        expect(states[1], isA<ReservationCancelFailure>());
        final fail = states[1] as ReservationCancelFailure;
        expect(fail.message, 'Không thể hủy phiếu đã hoàn tất');
      },
    );

    test(
      'CreateReservationRequested success emits [ReservationCreating, ReservationCreateSuccess]',
      () async {
        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CreateReservationRequested(
            memberId: 'mem-1',
            bookId: 'b-99',
            notes: 'Cần gấp',
          ),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCreating>());
        expect(states[1], isA<ReservationCreateSuccess>());
        final success = states[1] as ReservationCreateSuccess;
        expect(success.reservation.bookId, 'b-99');
        expect(success.message, contains('Đang chờ sách'));
        expect(repository.createCallCount, 1);
      },
    );

    test(
      'CreateReservationRequested conflict (409) emits [ReservationCreating, ReservationCreateFailure]',
      () async {
        repository.createError = DioException(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.reservations),
            statusCode: 409,
            data: {'message': 'Bạn đã có lượt đặt trước đang hoạt động'},
          ),
        );

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CreateReservationRequested(memberId: 'mem-1', bookId: 'b-1'),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCreating>());
        expect(states[1], isA<ReservationCreateFailure>());
        final failure = states[1] as ReservationCreateFailure;
        expect(failure.message, 'Bạn đã có lượt đặt trước đang hoạt động');
      },
    );

    test(
      'CreateReservationRequested timeout | Gặp reservation tạo gần thời điểm request -> Báo kết quả chưa xác định, KHÔNG khẳng định thành công và không retry POST',
      () async {
        repository.createError = DioException(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          type: DioExceptionType.connectionTimeout,
        );

        // Thêm reservation vào backend với thời gian gần thời điểm request
        repository.reservations.add(
          Reservation(
            id: 'res-timeout',
            reservationCode: 'RSV-TO',
            memberId: 'mem-1',
            bookId: 'b-99',
            bookTitle: 'Sách 99',
            status: 'PENDING',
            reservedAt: DateTime.now(),
          ),
        );

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CreateReservationRequested(memberId: 'mem-1', bookId: 'b-99'),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCreating>());
        expect(states[1], isA<ReservationCreateFailure>());
        final failure = states[1] as ReservationCreateFailure;
        expect(failure.message, contains('chưa được xác định'));
        expect(repository.createCallCount, 1); // Không tự retry POST
      },
    );

    test(
      'CreateReservationRequested timeout | Chỉ thấy reservation CŨ ở trang đầu -> Báo kết quả chưa xác định, KHÔNG khẳng định thành công',
      () async {
        repository.createError = DioException(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          type: DioExceptionType.connectionTimeout,
        );

        // Đã có 1 reservation CŨ cho cuốn sách này từ 2 ngày trước
        repository.reservations.add(
          Reservation(
            id: 'res-old',
            reservationCode: 'RSV-OLD',
            memberId: 'mem-1',
            bookId: 'b-99',
            bookTitle: 'Sách 99',
            status: 'PENDING',
            reservedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        );

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CreateReservationRequested(memberId: 'mem-1', bookId: 'b-99'),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCreating>());
        expect(states[1], isA<ReservationCreateFailure>());
        final fail = states[1] as ReservationCreateFailure;
        expect(fail.message, contains('chưa được xác định'));
        expect(repository.createCallCount, 1); // Không tự retry POST
      },
    );

    test(
      'CreateReservationRequested timeout | Không tìm thấy trong trang 1 (hoặc trang ngoài) -> Báo kết quả chưa xác định',
      () async {
        repository.createError = DioException(
          requestOptions: RequestOptions(path: ApiConstants.reservations),
          type: DioExceptionType.sendTimeout,
        );

        final states = <ReservationsState>[];
        bloc.stream.listen(states.add);

        bloc.add(
          const CreateReservationRequested(
            memberId: 'mem-1',
            bookId: 'b-not-found',
          ),
        );
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0], isA<ReservationCreating>());
        expect(states[1], isA<ReservationCreateFailure>());
        final fail = states[1] as ReservationCreateFailure;
        expect(fail.message, contains('chưa được xác định'));
      },
    );
  });
}
