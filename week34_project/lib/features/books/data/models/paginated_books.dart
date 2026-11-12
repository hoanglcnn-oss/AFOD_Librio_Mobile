import 'book.dart';

class PaginatedBooks {
  final List<Book> books;
  final int page;
  final int totalPages;
  final bool hasNextPage;

  const PaginatedBooks({
    required this.books,
    required this.page,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory PaginatedBooks.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;

    return PaginatedBooks(
      books: data
          .map((item) => Book.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int,
      totalPages: meta['totalPages'] as int,
      hasNextPage: meta['hasNextPage'] as bool,
    );
  }
}

