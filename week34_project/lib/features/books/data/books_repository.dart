import 'package:week34_project/features/books/data/models/book.dart';

import 'models/paginated_books.dart';

abstract class BooksRepository {
  Future<PaginatedBooks> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  });
  Future<Book> getBookById(String id);
  Future<Book> getBookByIsbn(String isbn);
}
