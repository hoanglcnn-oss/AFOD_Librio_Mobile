import 'package:dio/dio.dart';
import 'package:week34_project/core/storage/token_storage.dart';

import 'datasources/borrowings_remote_data_source.dart';
import 'borrowing_repository.dart';
import 'models/borrowing.dart';
import 'models/borrowings_page.dart';
import 'models/create_borrowing_request.dart';

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
}
