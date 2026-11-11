import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:week34_project/features/borrowings/bloc/borrowing_bloc.dart';
import 'package:week34_project/features/borrowings/bloc/borrowing_event.dart';
import 'package:week34_project/features/borrowings/bloc/borrowing_state.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  const request = CreateBorrowingRequest(memberId: 'mem-01', bookId: 'book-01');
  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
  test(
    'BorrowBookRequested | Repository thành công | Submitting -> Success, dữ liệu đúng',
    () async {
      final bloc = BorrowingBloc(
        borrowingRepository: FakeBorrowingRepository(),
      );

      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const BorrowBookRequested(request));

      final states = await statesFuture;

      expect(states[0], isA<BorrowingSubmitting>());
      expect(states[1], isA<BorrowingSuccess>());

      final success = states[1] as BorrowingSuccess;

      expect(success.borrowing.memberId, 'mem-01');
      expect(success.borrowing.bookId, 'book-01');
      expect(success.borrowing.status, 'BORROWED');

      await bloc.close();
    },
  );

  test(
    'BorrowBookRequested | Repository lỗi | Submitting -> Failure, có thông báo',
    () async {
      final bloc = BorrowingBloc(
        borrowingRepository: FakeBorrowingRepository(shouldFail: true),
      );

      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const BorrowBookRequested(request));

      final states = await statesFuture;

      expect(states[0], isA<BorrowingSubmitting>());
      expect(states[1], isA<BorrowingFailure>());

      final failure = states[1] as BorrowingFailure;

      expect(failure.message, isNotEmpty);

      await bloc.close();
    },
  );

  test('BorrowBookRequested | Đã Success | state vẫn là Success', () async {
    final bloc = BorrowingBloc(borrowingRepository: FakeBorrowingRepository());

    final successFuture = bloc.stream.firstWhere(
      (state) => state is BorrowingSuccess,
    );

    bloc.add(const BorrowBookRequested(request));

    await successFuture;

    // Gửi event lần hai sau khi đã thành công.
    bloc.add(const BorrowBookRequested(request));

    expect(bloc.state, isA<BorrowingSuccess>());

    await bloc.close();
  });

  test(
    'BorrowBookRequested | A mượn thành công, B gặp HTTP 409 | Success và Failure độc lập',
    () async {
      final repository = FakeBorrowingRepository();

      final blocA = BorrowingBloc(borrowingRepository: repository);
      final blocB = BorrowingBloc(borrowingRepository: repository);

      const requestA = CreateBorrowingRequest(
        memberId: 'member-A',
        bookId: 'book-last',
      );

      const requestB = CreateBorrowingRequest(
        memberId: 'member-B',
        bookId: 'book-last',
      );

      // Thành viên A được Backend chấp nhận.
      final statesAFuture = blocA.stream.take(2).toList();

      blocA.add(const BorrowBookRequested(requestA));

      final statesA = await statesAFuture;

      expect(statesA[0], isA<BorrowingSubmitting>());
      expect(statesA[1], isA<BorrowingSuccess>());

      final successA = statesA[1] as BorrowingSuccess;

      expect(successA.borrowing.memberId, 'member-A');
      expect(successA.borrowing.bookId, 'book-last');
      expect(successA.borrowing.status, 'BORROWED');

      // Giả lập tồn kho đã bị A lấy hết.
      final options = RequestOptions(path: '/borrowings');

      repository.borrowError = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {
            'statusCode': 409,
            'message':
                'Sách "Clean Code" vừa được độc giả khác '
                'mượn hết. Số lượng khả dụng không còn đủ '
                '1 cuốn, giao dịch đã được hủy bỏ',
            'error': 'Conflict',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      // Thành viên B gửi yêu cầu mượn cùng cuốn sách.
      final statesBFuture = blocB.stream.take(2).toList();

      blocB.add(const BorrowBookRequested(requestB));

      final statesB = await statesBFuture;

      expect(statesB[0], isA<BorrowingSubmitting>());
      expect(statesB[1], isA<BorrowingFailure>());

      final failureB = statesB[1] as BorrowingFailure;

      expect(failureB.message, contains('không còn đủ số lượng'));

      expect(failureB.message, contains('thành viên khác'));

      // B không được chuyển sang Success.
      expect(blocB.state, isA<BorrowingFailure>());

      // A vẫn giữ kết quả thành công.
      expect(blocA.state, isA<BorrowingSuccess>());

      // Đã có đúng hai yêu cầu từ hai thành viên.
      expect(repository.borrowCallCount, 2);

      expect(repository.borrowRequests[0].memberId, 'member-A');
      expect(repository.borrowRequests[1].memberId, 'member-B');

      expect(repository.borrowRequests[0].bookId, 'book-last');
      expect(repository.borrowRequests[1].bookId, 'book-last');

      await blocA.close();
      await blocB.close();
    },
  );
}
