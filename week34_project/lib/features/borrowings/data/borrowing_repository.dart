import 'models/borrowing.dart';
import 'models/create_borrowing_request.dart';
import 'models/borrowings_page.dart';

abstract class BorrowingRepository {
  Future<Borrowing> borrowBook(CreateBorrowingRequest request);
  Future<BorrowingsPage> getBorrowings({
    required String memberId,
    int page = 1,
    int limit = 10,
  });
}
