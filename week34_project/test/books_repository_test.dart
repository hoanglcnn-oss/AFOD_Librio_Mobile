import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/books/data/api_books_repository.dart';

void main() {
  test('GET /books trả về BooksPage', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/books');
          expect(options.queryParameters['page'], 1);
          expect(options.queryParameters['limit'], 10);

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': [
                  {
                    'id': 'book-01',
                    'title': 'Clean Code',
                    'isbn': '9780132350884',
                    'authorName': 'Robert C. Martin',
                    'categoryName': 'Programming',
                    'description': 'Software craftsmanship',
                    'copiesTotal': 5,
                    'copiesAvailable': 3,
                    'status': 'AVAILABLE',
                  },
                ],
                'meta': {
                  'page': 1,
                  'limit': 10,
                  'totalItems': 1,
                  'totalPages': 1,
                  'hasNextPage': false,
                },
              },
            ),
          );
        },
      ),
    );

    final repository = ApiBooksRepository(dio: dio);

    final result = await repository.getBooks(page: 1, limit: 10);

    expect(result.page, 1);
    expect(result.books, hasLength(1));
    expect(result.books.first.id, 'book-01');
    expect(result.books.first.title, 'Clean Code');
  });
}
