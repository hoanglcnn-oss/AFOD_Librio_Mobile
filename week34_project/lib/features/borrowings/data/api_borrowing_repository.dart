import 'package:dio/dio.dart';
import 'package:week34_project/core/storage/token_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'borrowing_repository.dart';
import 'models/borrowing.dart';
import 'models/create_borrowing_request.dart';

class ApiBorrowingRepository implements BorrowingRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiBorrowingRepository({Dio? dio, TokenStorage? tokenStorage})
    : _dio = dio ?? DioClient.dio,
      _tokenStorage = tokenStorage ?? TokenStorage();

  @override
  Future<Borrowing> borrowBook(CreateBorrowingRequest request) async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    final response = await _dio.post(
      ApiConstants.borrowings,
      data: request.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return Borrowing.fromJson(response.data as Map<String, dynamic>);
  }
}
