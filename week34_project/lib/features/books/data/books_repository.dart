import 'package:week34_project/features/books/data/models/book.dart';

import 'models/books_page.dart';

abstract class BooksRepository {
  Future<BooksPage> getBooks({int page = 1, int limit = 10, String? search});
  Future<Book> getBookById(String id);
  Future<Book> getBookByIsbn(String isbn);
}
