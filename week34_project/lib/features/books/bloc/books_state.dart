import 'package:equatable/equatable.dart';

import '../data/models/paginated_books.dart';

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
  final PaginatedBooks paginatedBooks;

  const BooksLoaded({required this.paginatedBooks});

  /// Getter for backward compatibility
  PaginatedBooks get booksPage => paginatedBooks;

  @override
  List<Object?> get props => [paginatedBooks];
}

class BooksFailure extends BooksState {
  final String message;

  const BooksFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
