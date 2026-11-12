import 'package:dio/dio.dart';
import 'package:week34_project/features/borrowing_slips/data/borrowing_slips_repository.dart';
import 'package:week34_project/features/borrowing_slips/data/models/borrowing_slip.dart';
import 'package:week34_project/features/borrowing_slips/data/models/create_borrowing_slip_request.dart';
import 'package:week34_project/features/borrowing_slips/data/models/paginated_borrowing_slips.dart';
import 'package:week34_project/features/borrowing_slips/data/models/return_slip_items_request.dart';
import 'package:week34_project/features/borrowings/data/borrowing_repository.dart';
import 'package:week34_project/features/borrowings/data/models/borrowing.dart';
import 'package:week34_project/features/borrowings/data/models/create_borrowing_request.dart';
import 'package:week34_project/features/borrowings/data/models/paginated_borrowings.dart';

class FakeBorrowingRepository
    implements BorrowingRepository, BorrowingSlipsRepository {
  bool shouldFail;
  bool shouldFailReturn = false;
  int returnCallCount = 0;
  bool shouldFailRenew = false;
  int renewCallCount = 0;
  int lastExtraDays = 0;
  bool shouldFailCreateSlip = false;
  int createSlipCallCount = 0;
  // Cho phép tạo các trường hợp test khác nhau.
  String fakeBorrowingStatus = 'BORROWED';
  int fakeRenewCount = 0;
  DateTime? fakeDueDate;
  DioException? createSlipErrorOnce;
  DioException? borrowError;
  int borrowCallCount = 0;
  int returnSlipCallCount = 0;
  ReturnSlipItemsRequest? lastReturnSlipRequest;
  DioException? returnSlipError;
  int paySlipFineCallCount = 0;
  DioException? paySlipFineError;
  int approveSlipCallCount = 0;
  int rejectSlipCallCount = 0;
  String? lastRejectionReason;

  int getPendingSlipsCallCount = 0;
  bool shouldFailGetPendingSlips = false;
  BorrowingSlipsPage? fakePendingSlipsPage;
  BorrowingSlipsPage Function(int page, int limit)? fakePendingSlipsBuilder;
  DioException? getPendingSlipsError;

  int getAllBorrowingsCallCount = 0;
  String? lastGetAllBorrowingsStatus;
  int? lastGetAllBorrowingsPage;
  bool shouldFailGetAllBorrowings = false;
  BorrowingsPage? fakeAllBorrowingsPage;
  BorrowingsPage Function(String? status, int page, int limit)?
  fakeAllBorrowingsBuilder;
  DioException? getAllBorrowingsError;

  int getAllSlipsCallCount = 0;
  String? lastGetAllSlipsStatus;
  int? lastGetAllSlipsPage;
  bool shouldFailGetAllSlips = false;
  BorrowingSlipsPage? fakeAllSlipsPage;
  BorrowingSlipsPage Function(String? status, int page, int limit)?
  fakeAllSlipsBuilder;
  DioException? getAllSlipsError;

  BorrowingSlip? fakeSlipDetail;

  DioException? approveSlipError;
  DioException? rejectSlipError;
  final List<CreateBorrowingRequest> borrowRequests = [];
  final List<CreateBorrowingSlipRequest> createSlipRequests = [];

  FakeBorrowingRepository({this.shouldFail = false});

  @override
  Future<Borrowing> borrowBook(CreateBorrowingRequest request) async {
    borrowCallCount++;
    borrowRequests.add(request);

    if (borrowError != null) {
      throw borrowError!;
    }

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
  Future<BorrowingSlip> createBorrowingSlip(
    CreateBorrowingSlipRequest request,
  ) async {
    createSlipCallCount++;
    createSlipRequests.add(request);

    // Giả lập Backend trả HTTP 400 đúng một lần.
    final error = createSlipErrorOnce;

    if (error != null) {
      createSlipErrorOnce = null;
      throw error;
    }

    if (shouldFailCreateSlip) {
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
      dueDate: fakeDueDate ?? DateTime.now().add(const Duration(days: 14)),
      status: fakeBorrowingStatus,
      renewCount: fakeRenewCount,
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
  Future<BorrowingsPage> getAllBorrowings({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    getAllBorrowingsCallCount++;
    lastGetAllBorrowingsStatus = status;
    lastGetAllBorrowingsPage = page;

    if (getAllBorrowingsError != null) {
      throw getAllBorrowingsError!;
    }

    if (shouldFailGetAllBorrowings) {
      throw Exception('Không thể tải danh sách mượn đơn lẻ');
    }

    if (fakeAllBorrowingsBuilder != null) {
      return fakeAllBorrowingsBuilder!(status, page, limit);
    }

    if (fakeAllBorrowingsPage != null) {
      return fakeAllBorrowingsPage!;
    }

    final borrowing = Borrowing(
      id: 'brw-01',
      transactionCode: 'BRW-2026-0001',
      memberId: 'mem-01',
      memberName: 'Nguyễn Văn An',
      bookId: 'book-01',
      bookTitle: 'Clean Code',
      borrowDate: DateTime.utc(2026, 10, 29),
      dueDate: DateTime.utc(2026, 11, 12),
      status: status ?? 'BORROWED',
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
  Future<BorrowingSlipsPage> getBorrowingSlips({
    required String memberId,
    int page = 1,
    int limit = 10,
  }) async {
    return BorrowingSlipsPage(
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
  Future<BorrowingSlipsPage> getPendingBorrowingSlips({
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

    return BorrowingSlipsPage(
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
  Future<BorrowingSlipsPage> getAllBorrowingSlips({
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

    return BorrowingSlipsPage(
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

  bool? lastReturnFinePaid;

  @override
  Future<Borrowing> returnBook({
    required String borrowingId,
    bool finePaid = false,
  }) async {
    returnCallCount++;
    lastReturnFinePaid = finePaid;

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
      items: [
        const BorrowingSlipItem(
          id: 'item-A',
          bookId: 'book-A',
          bookTitle: 'Sách A',
          quantity: 1,
          returnedQuantity: 1,
          status: 'RETURNED',
        ),
        const BorrowingSlipItem(
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
  Future<Borrowing> renewLoan({
    required String borrowingId,
    int extraDays = 7,
    String? notes,
  }) async {
    renewCallCount++;
    lastExtraDays = extraDays;

    if (shouldFailRenew) {
      throw Exception('Không thể gia hạn sách');
    }

    final oldDueDate =
        fakeDueDate ?? DateTime.now().add(const Duration(days: 14));

    final newDueDate = oldDueDate.add(Duration(days: extraDays));

    fakeDueDate = newDueDate;
    fakeRenewCount++;

    return Borrowing(
      id: borrowingId,
      transactionCode: 'BRW-2026-0001',
      memberId: 'mem-01',
      memberName: 'Nguyễn Văn An',
      bookId: 'book-01',
      bookTitle: 'Clean Code',
      borrowDate: DateTime.utc(2026, 11, 1),
      dueDate: newDueDate,
      status: 'BORROWED',
      renewCount: fakeRenewCount,
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
}
