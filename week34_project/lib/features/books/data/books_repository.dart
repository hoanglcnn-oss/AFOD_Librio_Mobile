import 'models/books_page.dart';

abstract class BooksRepository {
  Future<BooksPage> getBooks({int page = 1, int limit = 10, String? search});
}
