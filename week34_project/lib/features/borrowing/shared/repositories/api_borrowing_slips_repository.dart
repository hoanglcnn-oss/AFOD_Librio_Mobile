import 'package:dio/dio.dart';
import 'package:week34_project/core/storage/token_storage.dart';

import 'borrowing_slips_repository.dart';
import '../datasources/borrowing_slips_remote_data_source.dart';
import '../models/borrowing_slip.dart';
import '../models/paginated_borrowing_slips.dart';
import '../../../borrowing_slips/data/models/create_borrowing_slip_request.dart';
import '../../../borrowing_slips/data/models/return_slip_items_request.dart';

class ApiBorrowingSlipsRepository implements BorrowingSlipsRepository {
  final BorrowingSlipsRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  ApiBorrowingSlipsRepository({
    BorrowingSlipsRemoteDataSource? remoteDataSource,
    TokenStorage? tokenStorage,
    Dio? dio,
  }) : _remoteDataSource =
           remoteDataSource ?? BorrowingSlipsRemoteDataSourceImpl(dio: dio),
       _tokenStorage = tokenStorage ?? TokenStorage();

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
  Future<PaginatedBorrowingSlips> getBorrowingSlips({
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

    return PaginatedBorrowingSlips.fromJson(data);
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
  Future<PaginatedBorrowingSlips> getPendingBorrowingSlips({
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

    return PaginatedBorrowingSlips.fromJson(data);
  }

  @override
  Future<PaginatedBorrowingSlips> getAllBorrowingSlips({
    String? status,
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

    final data = await _remoteDataSource.getAllBorrowingSlips(
      token: token,
      status: status,
      page: page,
      limit: limit,
    );

    return PaginatedBorrowingSlips.fromJson(data);
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

    try {
      final data = await _remoteDataSource.approveBorrowingSlip(
        slipId: slipId.trim(),
        token: token,
      );

      return BorrowingSlip.fromJson(data);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        final code = responseData['code']?.toString() ??
            responseData['errorCode']?.toString();
        final message = responseData['message']?.toString() ?? '';
        final details = responseData['details'] is Map
            ? Map<String, dynamic>.from(responseData['details'] as Map)
            : null;

        if (code == 'BORROW_LIMIT_EXCEEDED' ||
            message.contains('BORROW_LIMIT_EXCEEDED') ||
            message.toLowerCase().contains('vượt quá hạn mức') ||
            message.toLowerCase().contains('vượt hạn mức')) {
          throw BorrowLimitExceededException(
            message: message.isNotEmpty
                ? message
                : 'Độc giả đã vượt quá hạn mức mượn sách cho phép.',
            code: code ?? 'BORROW_LIMIT_EXCEEDED',
            details: details,
          );
        }
      }
      rethrow;
    }
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

  @override
  Future<BorrowingSlip> renewSlip({
    required String slipId,
    int extraDays = 7,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (slipId.trim().isEmpty) {
      throw ArgumentError('Mã phiếu không được để trống');
    }

    if (extraDays < 1 || extraDays > 14) {
      throw ArgumentError.value(
        extraDays,
        'extraDays',
        'Số ngày gia hạn phải từ 1 đến 14',
      );
    }

    final data = await _remoteDataSource.renewSlip(
      slipId: slipId.trim(),
      token: token,
      extraDays: extraDays,
    );

    return BorrowingSlip.fromJson(data);
  }

  @override
  Future<BorrowingSlip> cancelBorrowingSlip({
    required String slipId,
    String? reason,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    if (slipId.trim().isEmpty) {
      throw ArgumentError('Mã phiếu mượn không được để trống');
    }

    final data = await _remoteDataSource.cancelBorrowingSlip(
      slipId: slipId.trim(),
      token: token,
      reason: reason,
    );

    return BorrowingSlip.fromJson(data);
  }
}
