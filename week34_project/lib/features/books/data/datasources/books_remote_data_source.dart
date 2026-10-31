import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

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

  BooksRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.dio;

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
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getBookById(String id) async {
    final response = await _dio.get(
      '${ApiConstants.books}/${Uri.encodeComponent(id)}',
    );

    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getBookByIsbn(String isbn) async {
    final normalizedIsbn = isbn.replaceAll(RegExp(r'[\s-]'), '');

    final response = await _dio.get(
      '${ApiConstants.books}/isbn/${Uri.encodeComponent(normalizedIsbn)}',
    );

    return response.data as Map<String, dynamic>;
  }
}

