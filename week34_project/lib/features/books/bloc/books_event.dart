import 'package:equatable/equatable.dart';

abstract class BooksEvent extends Equatable {
  const BooksEvent();

  @override
  List<Object?> get props => [];
}

class LoadBooks extends BooksEvent {
  const LoadBooks();
}

class SearchBooks extends BooksEvent {
  final String keyword;

  const SearchBooks(this.keyword);

  @override
  List<Object?> get props => [keyword];
}
