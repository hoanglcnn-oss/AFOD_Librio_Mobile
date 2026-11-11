import 'package:dio/dio.dart';
import 'package:week34_project/core/storage/token_storage.dart';

import 'datasources/borrowings_remote_data_source.dart';
import 'borrowing_repository.dart';
import 'models/borrowing.dart';
import 'models/borrowings_page.dart';
import 'models/borrowing_slip.dart';
import 'models/borrowing_slips_page.dart';
import 'models/create_borrowing_request.dart';
import 'models/create_borrowing_slip_request.dart';
import 'models/return_slip_items_request.dart';

class ApiBorrowingRepository implements BorrowingRepository {
  final BorrowingsRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  ApiBorrowingRepository({
    BorrowingsRemoteDataSource? remoteDataSource,
    TokenStorage? tokenStorage,
    Dio? dio,
  }) : _remoteDataSource =
           remoteDataSource ?? BorrowingsRemoteDataSourceImpl(dio: dio),
       _tokenStorage = tokenStorage ?? TokenStorage();

  @override
  Future<Borrowing> borrowBook(CreateBorrowingRequest request) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    final data = await _remoteDataSource.createBorrowing(
      data: request.toJson(),
      token: token,
    );

    return Borrowing.fromJson(data);
  }

  @override
  Future<BorrowingSlip> createBorrowingSlip(
    CreateBorrowingSlipRequest request,
  ) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (request.memberId.trim().isEmpty) {
      throw ArgumentError('Mã độc giả không được để trống');
    }

    if (request.items.isEmpty) {
      throw ArgumentError('Phiếu mượn phải có ít nhất một cuốn sách');
    }

    if (request.expectedReturnDays < 1 || request.expectedReturnDays > 30) {
      throw ArgumentError('Thời hạn mượn phải từ 1 đến 30 ngày');
    }

    for (final item in request.items) {
      if (item.bookId.trim().isEmpty ||
          item.quantity < 1 ||
          item.quantity > 5) {
        throw ArgumentError('Thông tin sách mượn không hợp lệ');
      }
    }

    final data = await _remoteDataSource.createBorrowingSlip(
      data: request.toJson(),
      token: token,
    );

    return BorrowingSlip.fromJson(data);
  }

  @override
  Future<BorrowingsPage> getBorrowings({
    required String memberId,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    final data = await _remoteDataSource.getBorrowings(
      memberId: memberId,
      token: token,
      page: page,
      limit: limit,
    );

    return BorrowingsPage.fromJson(data);
  }

  @override
  Future<BorrowingSlipsPage> getBorrowingSlips({
    required String memberId,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (memberId.trim().isEmpty) {
      throw ArgumentError('Mã độc giả không được để trống');
    }

    final data = await _remoteDataSource.getBorrowingSlips(
      memberId: memberId.trim(),
      token: token,
      page: page,
      limit: limit,
    );

    return BorrowingSlipsPage.fromJson(data);
  }

  @override
  Future<BorrowingSlip> getBorrowingSlipById({required String slipId}) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (slipId.trim().isEmpty) {
      throw ArgumentError('Mã phiếu mượn không được để trống');
    }

    final data = await _remoteDataSource.getBorrowingSlipById(
      slipId: slipId.trim(),
      token: token,
    );

    return BorrowingSlip.fromJson(data);
  }

  @override
  Future<BorrowingSlipsPage> getPendingBorrowingSlips({
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (page < 1 || limit < 1) {
      throw ArgumentError('Thông tin phân trang không hợp lệ');
    }

    final data = await _remoteDataSource.getPendingBorrowingSlips(
      token: token,
      page: page,
      limit: limit,
    );

    return BorrowingSlipsPage.fromJson(data);
  }

  @override
  Future<BorrowingSlip> approveBorrowingSlip({required String slipId}) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (slipId.trim().isEmpty) {
      throw ArgumentError('Mã phiếu không được để trống');
    }

    final data = await _remoteDataSource.approveBorrowingSlip(
      slipId: slipId.trim(),
      token: token,
    );

    return BorrowingSlip.fromJson(data);
  }

  @override
  Future<BorrowingSlip> rejectBorrowingSlip({
    required String slipId,
    required String reason,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (slipId.trim().isEmpty) {
      throw ArgumentError('Mã phiếu không được để trống');
    }

    if (reason.trim().isEmpty) {
      throw ArgumentError('Cần nhập lý do từ chối phiếu');
    }

    final data = await _remoteDataSource.rejectBorrowingSlip(
      slipId: slipId.trim(),
      reason: reason.trim(),
      token: token,
    );

    return BorrowingSlip.fromJson(data);
  }

  @override
  Future<Borrowing> returnBook({required String borrowingId}) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    final data = await _remoteDataSource.returnBook(
      borrowingId: borrowingId,
      token: token,
      data: const {'finePaid': false},
    );

    return Borrowing.fromJson(data);
  }

  @override
  Future<BorrowingSlip> returnSlipItems({
    required String slipId,
    required ReturnSlipItemsRequest request,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (slipId.trim().isEmpty) {
      throw ArgumentError('Mã phiếu mượn không được để trống');
    }

    if (request.items.isEmpty) {
      throw ArgumentError('Cần chọn ít nhất một sách để trả');
    }

    final ids = <String>{};

    for (final item in request.items) {
      if (item.itemId.trim().isEmpty || item.quantity < 1) {
        throw ArgumentError('Thông tin sách trả không hợp lệ');
      }

      if (!ids.add(item.itemId)) {
        throw ArgumentError('Một dòng sách không được chọn hai lần');
      }

      if (!const {'GOOD', 'DAMAGED', 'LOST'}.contains(item.returnCondition)) {
        throw ArgumentError('Tình trạng sách trả không hợp lệ');
      }
    }

    final data = await _remoteDataSource.returnSlipItems(
      slipId: slipId.trim(),
      token: token,
      data: request.toJson(),
    );

    return BorrowingSlip.fromJson(data);
  }

  @override
  Future<Borrowing> renewLoan({
    required String borrowingId,
    int extraDays = 7,
    String? notes,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (extraDays < 1 || extraDays > 14) {
      throw ArgumentError.value(
        extraDays,
        'extraDays',
        'Số ngày gia hạn phải từ 1 đến 14',
      );
    }

    final data = await _remoteDataSource.renewLoan(
      borrowingId: borrowingId,
      token: token,
      extraDays: extraDays,
      notes: notes,
    );

    return Borrowing.fromJson(data);
  }

  @override
  Future<BorrowingSlip> paySlipFine({required String slipId}) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (slipId.trim().isEmpty) {
      throw ArgumentError('Mã phiếu không được để trống');
    }

    final data = await _remoteDataSource.paySlipFine(
      slipId: slipId.trim(),
      token: token,
    );

    return BorrowingSlip.fromJson(data);
  }
}
