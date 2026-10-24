import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../data/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    // Đăng ký xử lý LoginRequested bằng on<LoginRequested>()
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
  }

  // Khi nhận LoginRequested:
  // emit AuthLoading()
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Truyền email, password từ event.
      await authRepository.login(event.email, event.password);
      // Nếu không xảy ra exception:
      emit(const AuthSuccess(message: 'Đăng nhập thành công'));
    } catch (error) {
      // Sử dụng thông báo lỗi.
      emit(AuthFailure(message: _errorMessage(error)));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.register(
        fullName: event.fullName,
        phone: event.phone,
        email: event.email,
        password: event.password,
      );
      emit(const AuthSuccess(message: 'Đăng ký thành công'));
    } catch (error) {
      emit(AuthFailure(message: _errorMessage(error)));
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 401) {
        return 'Tài khoản hoặc mật khẩu không chính xác';
      }

      if (statusCode == 409) {
        return 'Email hoặc số điện thoại đã được sử dụng';
      }

      if (statusCode == 400) {
        return 'Thông tin không hợp lệ, vui lòng kiểm tra lại';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối tới máy chủ';
      }

      return 'Lỗi máy chủ, vui lòng thử lại';
    }

    return 'Đã xảy ra lỗi không xác định';
  }
}
