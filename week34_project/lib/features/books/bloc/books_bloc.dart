import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/books_repository.dart';
import 'books_event.dart';
import 'books_state.dart';

class BooksBloc extends Bloc<BooksEvent, BooksState> {
  final BooksRepository booksRepository;

  BooksBloc({required this.booksRepository}) : super(const BooksInitial()) {
    on<LoadBooks>(_onLoadBooks);
  }

  Future<void> _onLoadBooks(LoadBooks event, Emitter<BooksState> emit) async {
    emit(const BooksLoading());

    try {
      final booksPage = await booksRepository.getBooks(page: 1, limit: 10);

      emit(BooksLoaded(booksPage: booksPage));
    } on DioException catch (error) {
      emit(BooksFailure(message: _getErrorMessage(error)));
    } catch (error) {
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
}
