import 'models/borrowing.dart';
import 'models/borrowings_page.dart';
import 'models/borrowing_slip.dart';
import 'models/borrowing_slips_page.dart';
import 'models/create_borrowing_request.dart';
import 'models/create_borrowing_slip_request.dart';
import 'models/return_slip_items_request.dart';

abstract class BorrowingRepository {
  Future<Borrowing> borrowBook(CreateBorrowingRequest request);
  Future<BorrowingSlip> createBorrowingSlip(CreateBorrowingSlipRequest request);

  Future<BorrowingsPage> getBorrowings({
    required String memberId,
    int page = 1,
    int limit = 10,
  });

  Future<BorrowingSlipsPage> getBorrowingSlips({
    required String memberId,
    int page = 1,
    int limit = 10,
  });

  Future<BorrowingSlip> getBorrowingSlipById({required String slipId});

  Future<Borrowing> returnBook({required String borrowingId});
  Future<Borrowing> renewLoan({
    required String borrowingId,
    int extraDays = 7,
    String? notes,
  });

  Future<BorrowingSlipsPage> getPendingBorrowingSlips({
    int page = 1,
    int limit = 10,
  });

  Future<BorrowingSlip> approveBorrowingSlip({required String slipId});

  Future<BorrowingSlip> rejectBorrowingSlip({
    required String slipId,
    required String reason,
  });

  Future<BorrowingSlip> returnSlipItems({
    required String slipId,
    required ReturnSlipItemsRequest request,
  });

  Future<BorrowingSlip> paySlipFine({required String slipId});
}
