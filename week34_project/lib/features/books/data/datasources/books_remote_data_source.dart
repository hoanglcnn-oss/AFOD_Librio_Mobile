import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';

abstract class BooksRemoteDataSource {
  Future<Map<String, dynamic>> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  });

  Future<Map<String, dynamic>> getBookById(String id);

  Future<Map<String, dynamic>> getBookByIsbn(String isbn);
}

class BooksRemoteDataSourceImpl implements BooksRemoteDataSource {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  BooksRemoteDataSourceImpl({Dio? dio, TokenStorage? tokenStorage})
    : _dio = dio ?? DioClient.dio,
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Options> _authOptions() async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw StateError('Phiên đăng nhập không tồn tại');
    }

    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<Map<String, dynamic>> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final response = await _dio.get(
      ApiConstants.books,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      options: await _authOptions(),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getBookById(String id) async {
    final response = await _dio.get(
      '${ApiConstants.books}/${Uri.encodeComponent(id)}',
      options: await _authOptions(),
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getBookByIsbn(String isbn) async {
    final normalizedIsbn = isbn.replaceAll(RegExp(r'[\s-]'), '');

    final response = await _dio.get(
      '${ApiConstants.books}/isbn/${Uri.encodeComponent(normalizedIsbn)}',
      options: await _authOptions(),
    );

    return response.data as Map<String, dynamic>;
  }
}
