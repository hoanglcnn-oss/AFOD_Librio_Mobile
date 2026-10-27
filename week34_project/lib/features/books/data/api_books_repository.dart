import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'books_repository.dart';
import 'models/books_page.dart';

class ApiBooksRepository implements BooksRepository {
  final Dio _dio;

  ApiBooksRepository({Dio? dio}) : _dio = dio ?? DioClient.dio;

  @override
  Future<BooksPage> getBooks({
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

    return BooksPage.fromJson(response.data as Map<String, dynamic>);
  }
}
