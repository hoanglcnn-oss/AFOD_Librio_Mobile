import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository authRepository;

  ForgotPasswordBloc({required this.authRepository})
    : super(const ForgotPasswordInitial()) {
    on<SubmitForgotPassword>(_onSubmitForgotPassword);
  }

  Future<void> _onSubmitForgotPassword(
    SubmitForgotPassword event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    // Tránh xử lý email rỗng.
    final email = event.email.trim();

    if (email.isEmpty) {
      emit(const ForgotPasswordFailure('Vui lòng nhập email'));
      return;
    }

    emit(const ForgotPasswordLoading());

    try {
      final message = await authRepository.forgotPassword(email);

      emit(ForgotPasswordSuccess(message));
    } on DioException catch (error) {
      if (error.response?.statusCode == 400) {
        emit(const ForgotPasswordFailure('Email không hợp lệ'));
        return;
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        emit(const ForgotPasswordFailure('Không thể kết nối tới máy chủ'));
        return;
      }

      emit(
        const ForgotPasswordFailure('Không thể gửi yêu cầu. Vui lòng thử lại.'),
      );
    } catch (_) {
      emit(const ForgotPasswordFailure('Đã xảy ra lỗi. Vui lòng thử lại.'));
    }
  }
}
