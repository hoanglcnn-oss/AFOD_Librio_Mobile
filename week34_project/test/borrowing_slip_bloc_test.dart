import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:week34_project/features/borrowing/create_slip/bloc/borrowing_slip_bloc.dart';
import 'package:week34_project/features/borrowing/create_slip/bloc/borrowing_slip_event.dart';
import 'package:week34_project/features/borrowing/create_slip/bloc/borrowing_slip_state.dart';
import 'package:week34_project/features/borrowing/create_slip/models/create_borrowing_slip_request.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  const request = CreateBorrowingSlipRequest(
    memberId: 'mem-01',
    items: [
      BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1),
      BorrowingSlipItemRequest(bookId: 'book-02', quantity: 2),
    ],
  );

  group('BorrowingSlipBloc', () {
    test(
      'CreateSlipRequested | Repository thành công | Submitting -> Success, trạng thái PENDING_APPROVAL',
      () async {
        final repository = FakeBorrowingRepository();
        final bloc = BorrowingSlipBloc(borrowingSlipsRepository: repository);

        final statesFuture = bloc.stream.take(2).toList();

        bloc.add(const CreateSlipRequested(request));

        final states = await statesFuture;

        expect(states[0], isA<BorrowingSlipSubmitting>());
        expect(states[1], isA<BorrowingSlipSuccess>());

        final success = states[1] as BorrowingSlipSuccess;

        expect(success.slip.memberId, 'mem-01');
        expect(success.slip.status, 'PENDING_APPROVAL');
        expect(success.slip.items.length, 2);
        expect(repository.createSlipCallCount, 1);

        await bloc.close();
      },
    );

    test(
      'CreateSlipRequested | Repository lỗi | Submitting -> Failure, có thông báo',
      () async {
        final repository = FakeBorrowingRepository()
          ..shouldFailCreateSlip = true;

        final bloc = BorrowingSlipBloc(borrowingSlipsRepository: repository);

        final statesFuture = bloc.stream.take(2).toList();

        bloc.add(const CreateSlipRequested(request));

        final states = await statesFuture;

        expect(states[0], isA<BorrowingSlipSubmitting>());
        expect(states[1], isA<BorrowingSlipFailure>());

        final failure = states[1] as BorrowingSlipFailure;

        expect(failure.message, isNotEmpty);
        expect(repository.createSlipCallCount, 1);

        await bloc.close();
      },
    );

    test(
      'CreateSlipRequested | Đã Success | bỏ qua event tiếp theo, không gọi lại Repository',
      () async {
        final repository = FakeBorrowingRepository();
        final bloc = BorrowingSlipBloc(borrowingSlipsRepository: repository);

        final successFuture = bloc.stream.firstWhere(
          (state) => state is BorrowingSlipSuccess,
        );

        bloc.add(const CreateSlipRequested(request));

        await successFuture;

        expect(repository.createSlipCallCount, 1);

        bloc.add(const CreateSlipRequested(request));

        // Cho BLoC xử lý event thứ hai.
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state, isA<BorrowingSlipSuccess>());
        expect(repository.createSlipCallCount, 1);

        await bloc.close();
      },
    );

    test(
      'CreateSlipRequested | Vượt hạn mức rồi giảm số lượng | Failure -> Retry -> Success',
      () async {
        final options = RequestOptions(path: '/borrowing-slips');

        const backendMessage =
            'Vượt quá hạn mức mượn: độc giả đang giữ '
            '4/5 cuốn, chỉ còn được mượn thêm 1 cuốn '
            'nhưng yêu cầu 2 cuốn';

        final repository = FakeBorrowingRepository()
          ..createSlipErrorOnce = DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {
                'statusCode': 400,
                'message': backendMessage,
                'error': 'Bad Request',
              },
            ),
            type: DioExceptionType.badResponse,
          );

        final bloc = BorrowingSlipBloc(borrowingSlipsRepository: repository);

        // Độc giả đang mượn 4/5, yêu cầu thêm 2 cuốn.
        const invalidRequest = CreateBorrowingSlipRequest(
          memberId: 'mem-01',
          items: [
            BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1),
            BorrowingSlipItemRequest(bookId: 'book-02', quantity: 1),
          ],
          expectedReturnDays: 14,
        );

        // Thu thập đủ 4 state của hai lần gửi.
        final statesFuture = bloc.stream.take(4).toList();

        // Lần 1: Backend từ chối.
        final failureFuture = bloc.stream.firstWhere(
          (state) => state is BorrowingSlipFailure,
        );

        bloc.add(const CreateSlipRequested(invalidRequest));

        final failure = await failureFuture as BorrowingSlipFailure;

        expect(failure.message, backendMessage);
        expect(bloc.state, isA<BorrowingSlipFailure>());
        expect(repository.createSlipCallCount, 1);

        // Xác nhận request gốc vẫn giữ 2 cuốn.
        expect(
          invalidRequest.items.fold<int>(0, (sum, item) => sum + item.quantity),
          2,
        );

        // Lần 2: Người dùng chỉ yêu cầu 1 cuốn.
        const adjustedRequest = CreateBorrowingSlipRequest(
          memberId: 'mem-01',
          items: [BorrowingSlipItemRequest(bookId: 'book-01', quantity: 1)],
          expectedReturnDays: 14,
        );

        bloc.add(const CreateSlipRequested(adjustedRequest));

        final states = await statesFuture;

        expect(states[0], isA<BorrowingSlipSubmitting>());
        expect(states[1], isA<BorrowingSlipFailure>());
        expect(states[2], isA<BorrowingSlipSubmitting>());
        expect(states[3], isA<BorrowingSlipSuccess>());

        final success = states[3] as BorrowingSlipSuccess;

        expect(success.slip.status, 'PENDING_APPROVAL');
        expect(success.slip.items.length, 1);

        // Repository nhận đúng hai request khác nhau.
        expect(repository.createSlipCallCount, 2);
        expect(repository.createSlipRequests.length, 2);

        expect(repository.createSlipRequests[0].items.length, 2);
        expect(repository.createSlipRequests[1].items.length, 1);

        // Không thay đổi thời hạn khi Retry.
        expect(repository.createSlipRequests[1].expectedReturnDays, 14);

        await bloc.close();
      },
    );
  });
}
