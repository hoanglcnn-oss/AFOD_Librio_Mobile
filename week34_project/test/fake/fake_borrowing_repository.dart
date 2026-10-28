import 'package:week34_project/features/borrowings/data/borrowing_repository.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';

class FakeBorrowingRepository implements BorrowingRepository {
  bool shouldFail;

  FakeBorrowingRepository({this.shouldFail = false});

  @override
  Future<Borrowing> borrowBook(CreateBorrowingRequest request) async {
    if (shouldFail) {
      throw Exception('Không thể mượn sách');
    }

    return Borrowing(
      id: 'brw-01',
      transactionCode: 'BRW-2026-0001',
      memberId: request.memberId,
      memberName: 'Nguyễn Văn An',
      bookId: request.bookId,
      bookTitle: 'Clean Code',
      borrowDate: DateTime.utc(2026, 10, 29),
      dueDate: DateTime.utc(
        2026,
        10,
        29,
      ).add(Duration(days: request.durationDays)),
      status: 'BORROWED',
    );
  }
}
