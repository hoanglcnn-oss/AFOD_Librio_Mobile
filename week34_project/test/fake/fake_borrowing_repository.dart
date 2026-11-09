import 'package:week34_project/features/borrowings/data/borrowing_repository.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';
import 'package:week34_project/features/borrowings/data/models/borrowings_page.dart';

class FakeBorrowingRepository implements BorrowingRepository {
  bool shouldFail;
  bool shouldFailReturn = false;
  int returnCallCount = 0;
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

  @override
  Future<BorrowingsPage> getBorrowings({
    required String memberId,
    int page = 1,
    int limit = 10,
  }) async {
    if (shouldFail) {
      throw Exception('Không thể tải danh sách mượn sách');
    }

    final borrowing = Borrowing(
      id: 'brw-01',
      transactionCode: 'BRW-2026-0001',
      memberId: memberId,
      memberName: 'Nguyễn Văn An',
      bookId: 'book-01',
      bookTitle: 'Clean Code',
      borrowDate: DateTime.utc(2026, 10, 29),
      dueDate: DateTime.utc(2026, 11, 12),
      status: 'BORROWED',
    );

    return BorrowingsPage(
      borrowings: [borrowing],
      page: page,
      limit: limit,
      totalItems: 1,
      totalPages: 1,
      hasNextPage: false,
    );
  }

  @override
  Future<Borrowing> returnBook({required String borrowingId}) async {
    returnCallCount++;

    if (shouldFailReturn) {
      throw Exception('Không thể trả sách');
    }

    return Borrowing(
      id: borrowingId,
      transactionCode: 'BRW-2026-0001',
      memberId: 'mem-01',
      memberName: 'Nguyễn Văn An',
      bookId: 'book-01',
      bookTitle: 'Clean Code',
      borrowDate: DateTime.utc(2026, 10, 29),
      dueDate: DateTime.utc(2026, 11, 12),
      status: 'RETURNED',
    );
  }
}
