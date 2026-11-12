import 'models/borrowing.dart';
import 'models/create_borrowing_request.dart';
import 'models/paginated_borrowings.dart';

abstract class BorrowingRepository {
  Future<Borrowing> borrowBook(CreateBorrowingRequest request);

  Future<PaginatedBorrowings> getBorrowings({
    required String memberId,
    int page = 1,
    int limit = 10,
  });

  Future<PaginatedBorrowings> getAllBorrowings({
    String? status,
    int page = 1,
    int limit = 10,
  });

  Future<Borrowing> getBorrowingById(String borrowingId);

  Future<Borrowing> returnBook({
    required String borrowingId,
    bool finePaid = false,
  });

  Future<Borrowing> renewLoan({
    required String borrowingId,
    int extraDays = 7,
    String? notes,
  });

  Future<Borrowing> payFine(String borrowingId);
}
