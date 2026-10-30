import 'package:week34_project/features/books/data/books_repository.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/books/data/models/books_page.dart';

class FakeBooksRepository implements BooksRepository {
  @override
  Future<BooksPage> getBooks({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    return BooksPage(
      page: page,
      totalPages: 1,
      hasNextPage: false,
      books: const [
        Book(
          id: 'book-01',
          isbn: '9780132350884',
          title: 'Clean Code',
          authorName: 'Robert C. Martin',
          categoryName: 'Programming',
          description: 'A book about writing clean code.',
          coverUrl: null,
          status: 'AVAILABLE',
          copiesAvailable: 3,
          copiesTotal: 5,
        ),
      ],
    );
  }

  @override
  Future<Book> getBookById(String id) async {
    final page = await getBooks();

    for (final book in page.books) {
      if (book.id == id) {
        return book;
      }
    }

    throw Exception('Không tìm thấy sách');
  }

  @override
  Future<Book> getBookByIsbn(String isbn) async {
    if (isbn.isEmpty) {
      throw Exception('ISBN không được để trống');
    }

    final page = await getBooks();

    for (final book in page.books) {
      if (book.isbn == isbn) {
        return book;
      }
    }

    throw Exception('Không tìm thấy sách với ISBN $isbn');
  }
}
