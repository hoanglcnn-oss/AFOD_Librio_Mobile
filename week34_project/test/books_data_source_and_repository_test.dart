import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/books/data/api_books_repository.dart';
import 'package:week34_project/features/books/data/datasources/books_remote_data_source.dart';

void main() {
  group('BooksRemoteDataSourceImpl', () {
    test('getBooks gửi GET /books với đúng queryParameters', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/books');
            expect(options.queryParameters['page'], 2);
            expect(options.queryParameters['limit'], 20);
            expect(options.queryParameters['search'], 'Flutter');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {
                      'id': 'b1',
                      'isbn': '9780132350884',
                      'title': 'Flutter in Action',
                      'authorName': 'Eric W.',
                      'categoryName': 'Tech',
                      'description': 'Flutter guide',
                      'coverUrl': null,
                      'status': 'AVAILABLE',
                      'copiesAvailable': 5,
                      'copiesTotal': 5,
                    },
                  ],
                  'meta': {'page': 2, 'totalPages': 5, 'hasNextPage': true},
                },
              ),
            );
          },
        ),
      );

      final dataSource = BooksRemoteDataSourceImpl(dio: dio);
      final result = await dataSource.getBooks(
        page: 2,
        limit: 20,
        search: ' Flutter ',
      );

      expect(result['data'], isA<List>());
      expect((result['data'] as List).length, 1);
      expect(result['meta']['page'], 2);
    });

    test('getBookById gửi GET /books/:id được encode URL', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/books/book%20123');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'book 123',
                  'isbn': '9780132350884',
                  'title': 'Clean Code',
                  'authorName': 'Robert C. Martin',
                  'categoryName': 'Tech',
                  'description': 'Desc',
                  'coverUrl': null,
                  'status': 'AVAILABLE',
                  'copiesAvailable': 2,
                  'copiesTotal': 5,
                },
              ),
            );
          },
        ),
      );

      final dataSource = BooksRemoteDataSourceImpl(dio: dio);
      final result = await dataSource.getBookById('book 123');

      expect(result['id'], 'book 123');
      expect(result['title'], 'Clean Code');
    });

    test('getBookByIsbn chuẩn hóa ISBN và gửi GET /books/isbn/:isbn', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'GET');
            expect(options.path, '/books/isbn/9780132350884');

            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'book-isbn-1',
                  'isbn': '9780132350884',
                  'title': 'Clean Code',
                  'authorName': 'Robert C. Martin',
                  'categoryName': 'Tech',
                  'description': 'Desc',
                  'coverUrl': null,
                  'status': 'AVAILABLE',
                  'copiesAvailable': 2,
                  'copiesTotal': 5,
                },
              ),
            );
          },
        ),
      );

      final dataSource = BooksRemoteDataSourceImpl(dio: dio);
      final result = await dataSource.getBookByIsbn(' 978-0-13-235088-4 ');

      expect(result['isbn'], '9780132350884');
    });
  });

  group('ApiBooksRepository', () {
    test('getBooks parse response thành BooksPage', () async {
      final mockDataSource = _FakeBooksRemoteDataSource(
        booksResponse: {
          'data': [
            {
              'id': 'b1',
              'isbn': '9780132350884',
              'title': 'Clean Code',
              'authorName': 'Robert C. Martin',
              'categoryName': 'Tech',
              'description': 'Desc',
              'coverUrl': null,
              'status': 'AVAILABLE',
              'copiesAvailable': 3,
              'copiesTotal': 5,
            },
          ],
          'meta': {'page': 1, 'totalPages': 1, 'hasNextPage': false},
        },
      );

      final repository = ApiBooksRepository(remoteDataSource: mockDataSource);
      final page = await repository.getBooks();

      expect(page.page, 1);
      expect(page.books.length, 1);
      expect(page.books.first.title, 'Clean Code');
      expect(page.books.first.canBorrow, isTrue);
    });

    test('getBookById parse response thành Book', () async {
      final mockDataSource = _FakeBooksRemoteDataSource(
        bookResponse: {
          'id': 'b1',
          'isbn': '9780132350884',
          'title': 'Clean Code',
          'authorName': 'Robert C. Martin',
          'categoryName': 'Tech',
          'description': 'Desc',
          'coverUrl': null,
          'status': 'AVAILABLE',
          'copiesAvailable': 1,
          'copiesTotal': 2,
        },
      );

      final repository = ApiBooksRepository(remoteDataSource: mockDataSource);
      final book = await repository.getBookById('b1');

      expect(book.id, 'b1');
      expect(book.title, 'Clean Code');
    });

    test('getBookByIsbn chuẩn hóa ISBN trước khi gọi DataSource', () async {
      final mockDataSource = _FakeBooksRemoteDataSource(
        bookResponse: {
          'id': 'b1',
          'isbn': '9780132350884',
          'title': 'Clean Code',
          'authorName': 'Robert C. Martin',
          'categoryName': 'Tech',
          'description': 'Desc',
          'coverUrl': null,
          'status': 'AVAILABLE',
          'copiesAvailable': 1,
          'copiesTotal': 2,
        },
      );

      final repository = ApiBooksRepository(remoteDataSource: mockDataSource);
      final book = await repository.getBookByIsbn('978-0-13-235088-4');

      expect(mockDataSource.lastRequestedIsbn, '9780132350884');
      expect(book.id, 'b1');
    });

    test('truyền lỗi DioException khi DataSource thất bại', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 404),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final repository = ApiBooksRepository(dio: dio);

      expect(
        () => repository.getBookById('not-found'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });
}

class _FakeBooksRemoteDataSource implements BooksRemoteDataSource {
  final Map<String, dynamic>? booksResponse;
  final Map<String, dynamic>? bookResponse;
  String? lastRequestedIsbn;

  _FakeBooksRemoteDataSource({this.booksResponse, this.bookResponse});

  @override
  Future<Map<String, dynamic>> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    return booksResponse!;
  }

  @override
  Future<Map<String, dynamic>> getBookById(String id) async {
    return bookResponse!;
  }

  @override
  Future<Map<String, dynamic>> getBookByIsbn(String isbn) async {
    lastRequestedIsbn = isbn;
    return bookResponse!;
  }
}

