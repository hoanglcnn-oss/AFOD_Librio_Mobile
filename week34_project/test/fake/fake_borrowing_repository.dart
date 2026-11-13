import 'dart:async';
import 'package:dio/dio.dart';
import 'package:week34_project/features/borrowing/shared/repositories/borrowing_slips_repository.dart';
import 'package:week34_project/features/borrowing/shared/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing_slips/data/models/create_borrowing_slip_request.dart';
import 'package:week34_project/features/borrowing/shared/models/paginated_borrowing_slips.dart';
import 'package:week34_project/features/borrowing_slips/data/models/return_slip_items_request.dart';
import 'package:week34_project/features/renewal/models/renewal_eligibility.dart';

class FakeBorrowingRepository implements BorrowingSlipsRepository {
  bool shouldFail;
  bool shouldFailCreateSlip = false;
  int createSlipCallCount = 0;
  Completer<void>? createSlipCompleter;
  DioException? createSlipErrorOnce;
  final List<CreateBorrowingSlipRequest> createSlipRequests = [];

  int renewSlipCallCount = 0;
  bool shouldFailRenewSlip = false;
  int lastRenewSlipExtraDays = 0;
  DioException? renewSlipError;
  BorrowingSlip? fakeRenewSlipResult;
  Completer<void>? renewSlipCompleter;

  int paySlipFineCallCount = 0;
  DioException? paySlipFineError;

  int cancelSlipCallCount = 0;
  String? lastCancelSlipReason;
  DioException? cancelSlipError;
  bool shouldFailCancelSlip = false;
  BorrowingSlip? fakeCancelSlipResult;
  Completer<void>? cancelSlipCompleter;

  int returnSlipCallCount = 0;
  ReturnSlipItemsRequest? lastReturnSlipRequest;
  DioException? returnSlipError;

  int approveSlipCallCount = 0;
  DioException? approveSlipError;
  Object? approveSlipException;

  int rejectSlipCallCount = 0;
  String? lastRejectionReason;
  DioException? rejectSlipError;

  int getPendingSlipsCallCount = 0;
  bool shouldFailGetPendingSlips = false;
  PaginatedBorrowingSlips? fakePendingSlipsPage;
  PaginatedBorrowingSlips Function(int page, int limit)?
      fakePendingSlipsBuilder;
  DioException? getPendingSlipsError;

  int getAllSlipsCallCount = 0;
  String? lastGetAllSlipsStatus;
  int? lastGetAllSlipsPage;
  bool shouldFailGetAllSlips = false;
  PaginatedBorrowingSlips? fakeAllSlipsPage;
  PaginatedBorrowingSlips Function(String? status, int page, int limit)?
      fakeAllSlipsBuilder;
  DioException? getAllSlipsError;

  BorrowingSlip? fakeSlipDetail;
  BorrowingSlip Function(String slipId)? fakeSlipDetailBuilder;
  int getBorrowingSlipByIdCallCount = 0;

  DateTime? fakeDueDate;
  int fakeRenewCount = 0;

  FakeBorrowingRepository({this.shouldFail = false});

  @override
  Future<BorrowingSlip> createBorrowingSlip(
    CreateBorrowingSlipRequest request,
  ) async {
    createSlipCallCount++;
    createSlipRequests.add(request);

    if (createSlipCompleter != null) {
      await createSlipCompleter!.future;
    }

    final error = createSlipErrorOnce;
    if (error != null) {
      createSlipErrorOnce = null;
      throw error;
    }

    if (shouldFailCreateSlip || shouldFail) {
      throw Exception('Không thể tạo phiếu mượn');
    }

    return BorrowingSlip(
      id: 'slip-01',
      slipNumber: 'SLIP-2026-0001',
      memberId: request.memberId,
      status: 'PENDING_APPROVAL',
      dueDate: DateTime.now().add(Duration(days: request.expectedReturnDays)),
      items: [
        for (var i = 0; i < request.items.length; i++)
          BorrowingSlipItem(
            id: 'item-$i',
            bookId: request.items[i].bookId,
            bookTitle: 'Sách kiểm thử',
            quantity: request.items[i].quantity,
            status: 'PENDING',
          ),
      ],
    );
  }

  @override
  Future<PaginatedBorrowingSlips> getBorrowingSlips({
    required String memberId,
    int page = 1,
    int limit = 10,
  }) async {
    if (shouldFail) {
      throw Exception('Không thể tải danh sách phiếu mượn');
    }

    return PaginatedBorrowingSlips(
      slips: const [],
      page: page,
      limit: limit,
      totalItems: 0,
      totalPages: 1,
      hasNextPage: false,
    );
  }

  @override
  Future<BorrowingSlip> getBorrowingSlipById({required String slipId}) async {
    getBorrowingSlipByIdCallCount++;
    if (fakeSlipDetailBuilder != null) {
      return fakeSlipDetailBuilder!(slipId);
    }
    if (fakeSlipDetail != null) {
      return fakeSlipDetail!;
    }

    return BorrowingSlip(
      id: slipId,
      slipNumber: 'SLIP-2026-0001',
      memberId: 'mem-01',
      status: 'BORROWED',
      dueDate: DateTime.utc(2026, 11, 15),
      items: const [
        BorrowingSlipItem(
          id: 'item-01',
          bookId: 'book-01',
          bookTitle: 'Sách kiểm thử',
          quantity: 1,
          status: 'BORROWING',
        ),
      ],
    );
  }

  @override
  Future<PaginatedBorrowingSlips> getPendingBorrowingSlips({
    int page = 1,
    int limit = 10,
  }) async {
    getPendingSlipsCallCount++;

    if (getPendingSlipsError != null) {
      throw getPendingSlipsError!;
    }

    if (shouldFailGetPendingSlips) {
      throw Exception('Không thể tải phiếu chờ duyệt');
    }

    if (fakePendingSlipsBuilder != null) {
      return fakePendingSlipsBuilder!(page, limit);
    }

    if (fakePendingSlipsPage != null) {
      return fakePendingSlipsPage!;
    }

    return PaginatedBorrowingSlips(
      slips: [
        BorrowingSlip(
          id: 'slip-01',
          slipNumber: 'SLIP-2026-0001',
          memberId: 'mem-01',
          status: 'PENDING_APPROVAL',
          dueDate: DateTime.utc(2026, 11, 25),
          items: const [
            BorrowingSlipItem(
              id: 'item-01',
              bookId: 'book-01',
              bookTitle: 'Clean Code',
              quantity: 2,
              status: 'PENDING',
            ),
          ],
        ),
      ],
      page: page,
      limit: limit,
      totalItems: 1,
      totalPages: 1,
      hasNextPage: false,
    );
  }

  @override
  Future<PaginatedBorrowingSlips> getAllBorrowingSlips({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    getAllSlipsCallCount++;
    lastGetAllSlipsStatus = status;
    lastGetAllSlipsPage = page;

    if (getAllSlipsError != null) {
      throw getAllSlipsError!;
    }

    if (shouldFailGetAllSlips) {
      throw Exception('Không thể tải danh sách phiếu');
    }

    if (fakeAllSlipsBuilder != null) {
      return fakeAllSlipsBuilder!(status, page, limit);
    }

    if (fakeAllSlipsPage != null) {
      return fakeAllSlipsPage!;
    }

    final allMockSlips = [
      BorrowingSlip(
        id: 'slip-01',
        slipNumber: 'SLIP-2026-0001',
        memberId: 'mem-01',
        status: status ?? 'BORROWED',
        dueDate: DateTime.utc(2026, 11, 25),
        items: const [
          BorrowingSlipItem(
            id: 'item-01',
            bookId: 'book-01',
            bookTitle: 'Clean Code',
            quantity: 1,
            status: 'BORROWING',
          ),
        ],
      ),
    ];

    return PaginatedBorrowingSlips(
      slips: allMockSlips,
      page: page,
      limit: limit,
      totalItems: allMockSlips.length,
      totalPages: 1,
      hasNextPage: false,
    );
  }

  @override
  Future<BorrowingSlip> approveBorrowingSlip({required String slipId}) async {
    approveSlipCallCount++;

    if (approveSlipException != null) {
      throw approveSlipException!;
    }

    if (approveSlipError != null) {
      throw approveSlipError!;
    }

    return BorrowingSlip(
      id: slipId,
      slipNumber: 'SLIP-2026-0001',
      memberId: 'mem-01',
      status: 'BORROWED',
      dueDate: DateTime.utc(2026, 11, 25),
      items: const [
        BorrowingSlipItem(
          id: 'item-01',
          bookId: 'book-01',
          bookTitle: 'Clean Code',
          quantity: 2,
          status: 'BORROWING',
        ),
      ],
    );
  }

  @override
  Future<BorrowingSlip> rejectBorrowingSlip({
    required String slipId,
    required String reason,
  }) async {
    rejectSlipCallCount++;
    lastRejectionReason = reason;

    if (rejectSlipError != null) {
      throw rejectSlipError!;
    }

    return BorrowingSlip(
      id: slipId,
      slipNumber: 'SLIP-2026-0001',
      memberId: 'mem-01',
      status: 'REJECTED',
      dueDate: DateTime.utc(2026, 11, 25),
      items: const [
        BorrowingSlipItem(
          id: 'item-01',
          bookId: 'book-01',
          bookTitle: 'Clean Code',
          quantity: 2,
          status: 'CANCELLED',
        ),
      ],
    );
  }

  @override
  Future<BorrowingSlip> returnSlipItems({
    required String slipId,
    required ReturnSlipItemsRequest request,
  }) async {
    returnSlipCallCount++;
    lastReturnSlipRequest = request;

    if (returnSlipError != null) {
      throw returnSlipError!;
    }

    return BorrowingSlip(
      id: slipId,
      slipNumber: 'SLIP-2026-0001',
      memberId: 'mem-01',
      status: 'PARTIAL_RETURNED',
      dueDate: DateTime.utc(2026, 11, 15),
      items: const [
        BorrowingSlipItem(
          id: 'item-A',
          bookId: 'book-A',
          bookTitle: 'Sách A',
          quantity: 1,
          returnedQuantity: 1,
          status: 'RETURNED',
        ),
        BorrowingSlipItem(
          id: 'item-C',
          bookId: 'book-C',
          bookTitle: 'Sách C',
          quantity: 1,
          status: 'BORROWING',
        ),
      ],
    );
  }

  @override
  Future<BorrowingSlip> paySlipFine({required String slipId}) async {
    paySlipFineCallCount++;

    if (paySlipFineError != null) {
      throw paySlipFineError!;
    }

    return BorrowingSlip(
      id: slipId,
      slipNumber: 'SLIP-2026-0001',
      memberId: 'mem-01',
      status: 'COMPLETED',
      dueDate: DateTime.utc(2026, 11, 15),
      totalFine: 25000,
      finePaid: true,
      finePaidAt: DateTime.utc(2026, 11, 20),
      items: const [],
    );
  }

  @override
  Future<BorrowingSlip> renewSlip({
    required String slipId,
    int extraDays = 7,
  }) async {
    renewSlipCallCount++;
    lastRenewSlipExtraDays = extraDays;

    if (renewSlipCompleter != null) {
      await renewSlipCompleter!.future;
    }

    if (renewSlipError != null) {
      throw renewSlipError!;
    }

    if (shouldFail || shouldFailRenewSlip) {
      throw Exception('Không thể gia hạn phiếu mượn');
    }

    if (fakeRenewSlipResult != null) {
      if (fakeSlipDetail != null) {
        fakeSlipDetail = fakeRenewSlipResult;
      }
      return fakeRenewSlipResult!;
    }

    final oldDueDate = fakeDueDate ??
        fakeSlipDetail?.dueDate ??
        DateTime.now().add(const Duration(days: 14));
    final newDueDate = oldDueDate.add(Duration(days: extraDays));
    fakeDueDate = newDueDate;

    final result = BorrowingSlip(
      id: slipId,
      slipNumber: fakeSlipDetail?.slipNumber ?? 'SLIP-2026-0001',
      memberId: fakeSlipDetail?.memberId ?? 'mem-01',
      memberName: fakeSlipDetail?.memberName,
      memberCardNumber: fakeSlipDetail?.memberCardNumber,
      status: fakeSlipDetail?.status ?? 'BORROWED',
      dueDate: newDueDate,
      renewCount: (fakeSlipDetail?.renewCount ?? fakeRenewCount) + 1,
      renewalEligibility: const RenewalEligibility(
        canRenew: false,
        reasonCode: 'MAX_RENEWALS_REACHED',
      ),
      items: fakeSlipDetail?.items ?? const [],
    );
    if (fakeSlipDetail != null) {
      fakeSlipDetail = result;
    }
    return result;
  }

  @override
  Future<BorrowingSlip> cancelBorrowingSlip({
    required String slipId,
    String? reason,
  }) async {
    cancelSlipCallCount++;
    lastCancelSlipReason = reason;

    if (cancelSlipCompleter != null) {
      await cancelSlipCompleter!.future;
    }

    if (cancelSlipError != null) {
      throw cancelSlipError!;
    }

    if (shouldFail || shouldFailCancelSlip) {
      throw Exception('Không thể hủy phiếu mượn');
    }

    if (fakeCancelSlipResult != null) {
      if (fakeSlipDetail != null) {
        fakeSlipDetail = fakeCancelSlipResult;
      }
      return fakeCancelSlipResult!;
    }

    final result = BorrowingSlip(
      id: slipId,
      slipNumber: fakeSlipDetail?.slipNumber ?? 'SLIP-2026-0001',
      memberId: fakeSlipDetail?.memberId ?? 'mem-01',
      memberName: fakeSlipDetail?.memberName,
      memberCardNumber: fakeSlipDetail?.memberCardNumber,
      status: 'CANCELLED',
      dueDate: fakeSlipDetail?.dueDate ??
          DateTime.now().add(const Duration(days: 14)),
      items: fakeSlipDetail?.items ?? const [],
    );

    if (fakeSlipDetail != null) {
      fakeSlipDetail = result;
    }

    return result;
  }
}
