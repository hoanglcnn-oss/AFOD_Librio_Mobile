import 'models/borrowing.dart';
import 'models/create_borrowing_request.dart';

abstract class BorrowingRepository {
  Future<Borrowing> borrowBook(CreateBorrowingRequest request);
}
