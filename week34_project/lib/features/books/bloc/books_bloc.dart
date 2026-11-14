import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/books_repository.dart';
import '../data/models/book.dart';
import '../data/models/paginated_books.dart';
import 'books_event.dart';
import 'books_state.dart';

class BooksBloc extends Bloc<BooksEvent, BooksState> {
  final BooksRepository booksRepository;
  String? _currentKeyword;

  BooksBloc({required this.booksRepository}) : super(const BooksInitial()) {
    on<LoadBooks>(_onLoadBooks);
    on<SearchBooks>(_onSearchBooks);
    on<LoadMoreBooks>(_onLoadMoreBooks);
  }

  Future<void> _onLoadBooks(LoadBooks event, Emitter<BooksState> emit) async {
    _currentKeyword = null;
    emit(const BooksLoading());

    try {
      final paginatedBooks = await booksRepository.getBooks(page: 1, limit: 10);

      emit(BooksLoaded(paginatedBooks: paginatedBooks));
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[BooksBloc] DioException while loading books: '
          'path=${error.requestOptions.path}, '
          'status=${error.response?.statusCode}, '
          'data=${error.response?.data}, '
          'error=${error.error}',
        );
      }
      emit(BooksFailure(message: _getErrorMessage(error)));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[BooksBloc] Unexpected error while loading books: $error\n$stackTrace',
        );
      }
      emit(const BooksFailure(message: 'Không thể xử lý dữ liệu sách'));
    }
  }

  String _getErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối tới máy chủ';
    }

    if (error.response?.statusCode == 500) {
      return 'Máy chủ đang gặp sự cố';
    }

    return 'Không thể tải danh sách sách';
  }

  Future<void> _onSearchBooks(
    SearchBooks event,
    Emitter<BooksState> emit,
  ) async {
    final trimmed = event.keyword.trim();
    _currentKeyword = trimmed.isEmpty ? null : trimmed;
    emit(const BooksLoading());

    try {
      final result = await booksRepository.getBooks(
        page: 1,
        limit: 10,
        search: _currentKeyword,
      );

      emit(BooksLoaded(paginatedBooks: result));
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[BooksBloc] DioException while searching books: '
          'path=${error.requestOptions.path}, '
          'status=${error.response?.statusCode}, '
          'data=${error.response?.data}, '
          'error=${error.error}',
        );
      }
      emit(BooksFailure(message: _getErrorMessage(error)));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[BooksBloc] Unexpected error while searching books: $error\n$stackTrace',
        );
      }
      emit(const BooksFailure(message: 'Không thể tìm kiếm sách'));
    }
  }

  Future<void> _onLoadMoreBooks(
    LoadMoreBooks event,
    Emitter<BooksState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BooksLoaded) return;
    if (currentState.isLoadingMore ||
        !currentState.paginatedBooks.hasNextPage) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true, paginationError: null));

    try {
      final nextPage = currentState.paginatedBooks.page + 1;
      final result = await booksRepository.getBooks(
        page: nextPage,
        limit: 10,
        search: _currentKeyword,
      );

      final combinedBooks = List<Book>.from(currentState.paginatedBooks.books)
        ..addAll(result.books);

      final newPaginated = PaginatedBooks(
        books: combinedBooks,
        page: result.page,
        totalPages: result.totalPages,
        hasNextPage: result.hasNextPage,
      );

      emit(BooksLoaded(paginatedBooks: newPaginated, isLoadingMore: false));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[BooksBloc] Error while loading more books: $error\n$stackTrace',
        );
      }
      emit(
        currentState.copyWith(
          isLoadingMore: false,
          paginationError: 'Không thể tải thêm sách.',
        ),
      );
    }
  }
}
