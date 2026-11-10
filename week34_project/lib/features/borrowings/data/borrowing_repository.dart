import 'models/borrowing.dart';
import 'models/borrowings_page.dart';
import 'models/borrowing_slip.dart';
import 'models/create_borrowing_request.dart';
import 'models/create_borrowing_slip_request.dart';

abstract class BorrowingRepository {
  Future<Borrowing> borrowBook(CreateBorrowingRequest request);
  Future<BorrowingSlip> createBorrowingSlip(CreateBorrowingSlipRequest request);
  Future<BorrowingsPage> getBorrowings({
    required String memberId,
    int page = 1,
    int limit = 10,
  });
  Future<Borrowing> returnBook({required String borrowingId});
  Future<Borrowing> renewLoan({
    required String borrowingId,
    int extraDays = 7,
    String? notes,
  });
}
