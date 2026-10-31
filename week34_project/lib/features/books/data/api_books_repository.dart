import 'package:dio/dio.dart';
import 'package:week34_project/features/books/data/models/book.dart';

import 'datasources/books_remote_data_source.dart';
import 'books_repository.dart';
import 'models/books_page.dart';

class ApiBooksRepository implements BooksRepository {
  final BooksRemoteDataSource _remoteDataSource;

  ApiBooksRepository({BooksRemoteDataSource? remoteDataSource, Dio? dio})
    : _remoteDataSource =
          remoteDataSource ?? BooksRemoteDataSourceImpl(dio: dio);

  @override
  Future<BooksPage> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final data = await _remoteDataSource.getBooks(
      page: page,
      limit: limit,
      search: search,
    );

    return BooksPage.fromJson(data);
  }

  @override
  Future<Book> getBookById(String id) async {
    final data = await _remoteDataSource.getBookById(id);

    return Book.fromJson(data);
  }

  @override
  Future<Book> getBookByIsbn(String isbn) async {
    final normalizedIsbn = isbn.replaceAll(RegExp(r'[\s-]'), '');
    final data = await _remoteDataSource.getBookByIsbn(normalizedIsbn);

    return Book.fromJson(data);
  }
}
