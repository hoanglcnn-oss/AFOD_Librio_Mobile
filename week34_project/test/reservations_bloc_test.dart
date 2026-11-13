import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/core/constants/api_constants.dart';
import 'package:week34_project/features/reservations/bloc/reservations_bloc.dart';
import 'package:week34_project/features/reservations/bloc/reservations_event.dart';
import 'package:week34_project/features/reservations/bloc/reservations_state.dart';
import 'package:week34_project/features/reservations/data/models/reservation.dart';

import 'fake/fake_reservations_repository.dart';

void main() {
  group('ReservationsBloc', () {
    late FakeReservationsRepository repository;
    late ReservationsBloc bloc;

    final initialReservation = Reservation(
      id: 'res-1',
      reservationNumber: 'RSV-001',
      memberId: 'mem-1',
      bookId: 'b-1',
      bookTitle: 'Clean Code',
      status: 'PENDING',
      reservationDate: DateTime(2026, 11, 10),
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

    test('LoadReservations success emits [ReservationsLoading, ReservationsLoaded]', () async {
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
    });

    test('LoadReservations failure emits [ReservationsLoading, ReservationsFailure]', () async {
      repository.shouldFailGet = true;

      final states = <ReservationsState>[];
      bloc.stream.listen(states.add);

      bloc.add(const LoadReservations(memberId: 'mem-1'));
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ReservationsLoading>());
      expect(states[1], isA<ReservationsFailure>());
    });

    test('RefreshReservations updates loaded reservations without showing initial loading', () async {
      // Đầu tiên load thành công
      bloc.add(const LoadReservations(memberId: 'mem-1'));
      await Future.delayed(Duration.zero);
      expect(bloc.state, isA<ReservationsLoaded>());

      // Thêm 1 reservation mới vào repo
      repository.reservations.add(
        Reservation(
          id: 'res-2',
          reservationNumber: 'RSV-002',
          memberId: 'mem-1',
          bookId: 'b-2',
          bookTitle: 'Design Patterns',
          status: 'READY',
          reservationDate: DateTime.now(),
        ),
      );

      bloc.add(const RefreshReservations('mem-1'));
      await Future.delayed(Duration.zero);

      expect(bloc.state, isA<ReservationsLoaded>());
      final loaded = bloc.state as ReservationsLoaded;
      expect(loaded.reservations.length, 2);
    });

    test('CancelReservationRequested success emits [ReservationCancelling, ReservationCancelSuccess]', () async {
      bloc.add(const LoadReservations(memberId: 'mem-1'));
      await Future.delayed(Duration.zero);

      final states = <ReservationsState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CancelReservationRequested(
        reservationId: 'res-1',
        memberId: 'mem-1',
        reason: 'Không cần nữa',
      ));
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ReservationCancelling>());
      expect(states[1], isA<ReservationCancelSuccess>());

      final success = states[1] as ReservationCancelSuccess;
      expect(success.paginated.items.first.status, 'CANCELLED');
      expect(repository.cancelCallCount, 1);
    });

    test('CancelReservationRequested prevents duplicate submit when cancelling', () async {
      bloc.add(const LoadReservations(memberId: 'mem-1'));
      await Future.delayed(Duration.zero);

      repository.cancelCompleter = Completer<void>();

      // Gửi lần 1
      bloc.add(const CancelReservationRequested(
        reservationId: 'res-1',
        memberId: 'mem-1',
      ));
      await Future.delayed(Duration.zero);
      expect(bloc.state, isA<ReservationCancelling>());
      expect(repository.cancelCallCount, 1);

      // Gửi lần 2 trong lúc đang xử lý
      bloc.add(const CancelReservationRequested(
        reservationId: 'res-1',
        memberId: 'mem-1',
      ));
      await Future.delayed(Duration.zero);
      expect(repository.cancelCallCount, 1); // Vẫn chỉ gọi 1 lần

      repository.cancelCompleter!.complete();
      await Future.delayed(Duration.zero);
      expect(bloc.state, isA<ReservationCancelSuccess>());
    });

    test('CancelReservationRequested timeout | Backend xác nhận đã hủy -> Success không gọi lại PATCH', () async {
      bloc.add(const LoadReservations(memberId: 'mem-1'));
      await Future.delayed(Duration.zero);

      // Giả lập PATCH bị timeout nhưng thực tế Backend đã cập nhật trạng thái
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

      bloc.add(const CancelReservationRequested(
        reservationId: 'res-1',
        memberId: 'mem-1',
      ));
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ReservationCancelling>());
      expect(states[1], isA<ReservationCancelSuccess>());
      expect(repository.cancelCallCount, 1); // Không tự retry mutation
      expect(repository.getByIdCallCount, 1); // Kiểm tra lại qua GET
    });

    test('CancelReservationRequested timeout | Backend chưa hủy -> Failure không gọi lại PATCH', () async {
      bloc.add(const LoadReservations(memberId: 'mem-1'));
      await Future.delayed(Duration.zero);

      // Giả lập PATCH bị timeout và reservation vẫn PENDING
      repository.cancelError = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        type: DioExceptionType.receiveTimeout,
      );

      final states = <ReservationsState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CancelReservationRequested(
        reservationId: 'res-1',
        memberId: 'mem-1',
      ));
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ReservationCancelling>());
      expect(states[1], isA<ReservationCancelFailure>());
      expect(repository.cancelCallCount, 1); // Không tự retry PATCH
    });

    test('CancelReservationRequested non-timeout error -> ReservationCancelFailure', () async {
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

      bloc.add(const CancelReservationRequested(
        reservationId: 'res-1',
        memberId: 'mem-1',
      ));
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ReservationCancelling>());
      expect(states[1], isA<ReservationCancelFailure>());
      final fail = states[1] as ReservationCancelFailure;
      expect(fail.message, 'Không thể hủy phiếu đã hoàn tất');
    });

    test('CreateReservationRequested success emits [ReservationCreating, ReservationCreateSuccess]', () async {
      final states = <ReservationsState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateReservationRequested(
        memberId: 'mem-1',
        bookId: 'b-99',
        notes: 'Cần gấp',
      ));
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ReservationCreating>());
      expect(states[1], isA<ReservationCreateSuccess>());
      final success = states[1] as ReservationCreateSuccess;
      expect(success.reservation.bookId, 'b-99');
      expect(success.message, contains('Đang chờ sách'));
      expect(repository.createCallCount, 1);
    });

    test('CreateReservationRequested conflict (409) emits [ReservationCreating, ReservationCreateFailure]', () async {
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

      bloc.add(const CreateReservationRequested(
        memberId: 'mem-1',
        bookId: 'b-1',
      ));
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ReservationCreating>());
      expect(states[1], isA<ReservationCreateFailure>());
      final failure = states[1] as ReservationCreateFailure;
      expect(failure.message, 'Bạn đã có lượt đặt trước đang hoạt động');
    });

    test('CreateReservationRequested timeout | Backend xác nhận -> Success không gọi lại POST', () async {
      repository.createError = DioException(
        requestOptions: RequestOptions(path: ApiConstants.reservations),
        type: DioExceptionType.connectionTimeout,
      );

      // Thêm reservation vào backend như thể request ban đầu đã thành công
      repository.reservations.add(
        Reservation(
          id: 'res-timeout',
          reservationNumber: 'RSV-TO',
          memberId: 'mem-1',
          bookId: 'b-99',
          bookTitle: 'Sách 99',
          status: 'PENDING',
          reservationDate: DateTime.now(),
        ),
      );

      final states = <ReservationsState>[];
      bloc.stream.listen(states.add);

      bloc.add(const CreateReservationRequested(
        memberId: 'mem-1',
        bookId: 'b-99',
      ));
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<ReservationCreating>());
      expect(states[1], isA<ReservationCreateSuccess>());
      expect(repository.createCallCount, 1); // Không tự retry POST
    });
  });
}
