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
  final bool isLoadingMore;
  final String? paginationError;

  const BooksLoaded({
    required this.paginatedBooks,
    this.isLoadingMore = false,
    this.paginationError,
  });

  /// Getter for backward compatibility
  PaginatedBooks get booksPage => paginatedBooks;

  BooksLoaded copyWith({
    PaginatedBooks? paginatedBooks,
    bool? isLoadingMore,
    String? paginationError,
  }) {
    return BooksLoaded(
      paginatedBooks: paginatedBooks ?? this.paginatedBooks,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: paginationError,
    );
  }

  @override
  List<Object?> get props => [paginatedBooks, isLoadingMore, paginationError];
}

class BooksFailure extends BooksState {
  final String message;

  const BooksFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
