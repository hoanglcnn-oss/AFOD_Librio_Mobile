import 'models/borrowing_slip.dart';
import 'models/create_borrowing_slip_request.dart';
import 'models/paginated_borrowing_slips.dart';
import 'models/return_slip_items_request.dart';

abstract class BorrowingSlipsRepository {
  Future<BorrowingSlip> createBorrowingSlip(CreateBorrowingSlipRequest request);

  Future<PaginatedBorrowingSlips> getBorrowingSlips({
    required String memberId,
    int page = 1,
    int limit = 10,
  });

  Future<BorrowingSlip> getBorrowingSlipById({required String slipId});

  Future<PaginatedBorrowingSlips> getPendingBorrowingSlips({
    int page = 1,
    int limit = 10,
  });

  Future<PaginatedBorrowingSlips> getAllBorrowingSlips({
    String? status,
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

  Future<BorrowingSlip> renewSlip({
    required String slipId,
    int extraDays = 7,
  });

  Future<BorrowingSlip> paySlipFine({required String slipId});

  Future<BorrowingSlip> cancelBorrowingSlip({
    required String slipId,
    String? reason,
  });
}

/// Ngoại lệ ném ra khi duyệt phiếu mượn nhưng độc giả vượt quá hạn mức cho phép
class BorrowLimitExceededException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const BorrowLimitExceededException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => message;
}
