import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';

import 'fake/fake_borrowing_repository.dart';

void main() {
  group('BorrowingRepository', () {
    const request = CreateBorrowingRequest(
      memberId: 'mem-01',
      bookId: 'book-01',
      durationDays: 14,
    );

    test('borrowBook tạo phiếu mượn thành công', () async {
      // Arrange
      final repository = FakeBorrowingRepository();

      // Act
      final result = await repository.borrowBook(request);

      // Assert
      expect(result.id, 'brw-01');
      expect(result.memberId, 'mem-01');
      expect(result.bookId, 'book-01');
      expect(result.transactionCode, isNotEmpty);
      expect(result.status, 'BORROWED');

      expect(result.dueDate.difference(result.borrowDate).inDays, 14);
    });

    test('borrowBook ném lỗi khi repository thất bại', () async {
      // Arrange
      final repository = FakeBorrowingRepository(shouldFail: true);

      // Act & Assert
      await expectLater(
        repository.borrowBook(request),
        throwsA(isA<Exception>()),
      );
    });
  });
}
