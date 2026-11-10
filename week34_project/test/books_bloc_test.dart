import 'package:flutter_test/flutter_test.dart';

import 'package:week34_project/features/books/bloc/books_bloc.dart';
import 'package:week34_project/features/books/bloc/books_event.dart';
import 'package:week34_project/features/books/bloc/books_state.dart';

import 'fake/fake_books_repository.dart';

void main() {
  // Event | Điều kiện đầu vào | Kết quả được kiểm chứng
  test(
    'LoadBooks | Repository có 1 sách | Loading -> Loaded, dữ liệu đúng',
    () async {
      final bloc = BooksBloc(booksRepository: FakeBooksRepository());

      final statesFuture = bloc.stream.take(2).toList();

      bloc.add(const LoadBooks());

      final states = await statesFuture;

      expect(states[0], isA<BooksLoading>());
      expect(states[1], isA<BooksLoaded>());

      final loaded = states[1] as BooksLoaded;

      expect(loaded.booksPage.books.length, 1);
      expect(loaded.booksPage.books.first.title, 'Clean Code');
      expect(loaded.booksPage.hasNextPage, false);

      await bloc.close();
    },
  );
}
