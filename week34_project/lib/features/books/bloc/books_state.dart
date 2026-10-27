import 'package:equatable/equatable.dart';

import '../data/models/books_page.dart';

abstract class BooksState extends Equatable {
  const BooksState();

  @override
  List<Object?> get props => [];
}

class BooksInitial extends BooksState {
  const BooksInitial();
}

class BooksLoading extends BooksState {
  const BooksLoading();
}

class BooksLoaded extends BooksState {
  final BooksPage booksPage;

  const BooksLoaded({required this.booksPage});

  @override
  List<Object?> get props => [booksPage];
}

class BooksFailure extends BooksState {
  final String message;

  const BooksFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
