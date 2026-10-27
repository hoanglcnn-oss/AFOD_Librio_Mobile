import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/books/data/api_books_repository.dart';

void main() {
  test('GET /books trả về BooksPage', () async {
    final repository = ApiBooksRepository();

    final result = await repository.getBooks(page: 1, limit: 10);

    expect(result.page, 1);
    expect(result.books, isA<List>());
    expect(result.totalPages, greaterThanOrEqualTo(0));

    if (result.books.isNotEmpty) {
      expect(result.books.first.id, isNotEmpty);
      expect(result.books.first.title, isNotEmpty);
    }
  });
}
