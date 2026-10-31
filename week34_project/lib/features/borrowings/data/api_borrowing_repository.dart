import 'package:dio/dio.dart';
import 'package:week34_project/core/storage/token_storage.dart';

import 'datasources/borrowings_remote_data_source.dart';
import 'borrowing_repository.dart';
import 'models/borrowing.dart';
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
}
