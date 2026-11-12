import 'package:dio/dio.dart';
import 'package:week34_project/core/storage/token_storage.dart';

import 'borrowing_repository.dart';
import 'datasources/borrowings_remote_data_source.dart';
import 'models/borrowing.dart';
import 'models/create_borrowing_request.dart';
import 'models/paginated_borrowings.dart';

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
  Future<PaginatedBorrowings> getBorrowings({
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

    return PaginatedBorrowings.fromJson(data);
  }

  @override
  Future<PaginatedBorrowings> getAllBorrowings({
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

    final data = await _remoteDataSource.getAllBorrowings(
      token: token,
      status: status,
      page: page,
      limit: limit,
    );

    return PaginatedBorrowings.fromJson(data);
  }

  @override
  Future<Borrowing> returnBook({
    required String borrowingId,
    bool finePaid = false,
  }) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    final data = await _remoteDataSource.returnBook(
      borrowingId: borrowingId,
      token: token,
      data: {'finePaid': finePaid},
    );

    return Borrowing.fromJson(data);
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
  Future<Borrowing> payFine(String borrowingId) async {
    if (borrowingId.trim().isEmpty) {
      throw ArgumentError.value(
        borrowingId,
        'borrowingId',
        'Mã lượt mượn không được để trống',
      );
    }

    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    final data = await _remoteDataSource.payFine(
      borrowingId: borrowingId.trim(),
      token: token,
    );

    return Borrowing.fromJson(data);
  }
}
