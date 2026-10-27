import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../data/auth_repository.dart';
import '../../../core/storage/token_storage.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final TokenStorage tokenStorage;
  AuthBloc({required this.authRepository, required this.tokenStorage})
    : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<RestoreSessionRequested>(_onRestoreSessionRequested);
  }

  // Khi nhận LoginRequested:
  // emit AuthLoading()
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await authRepository.login(event.email, event.password);

      // Chỉ lưu JWT khi backend trả về đăng nhập thành công.
      await tokenStorage.saveToken(response.accessToken);

      // Chỉ authenticated sau khi lưu token thành công.
      emit(AuthAuthenticated(user: response.user));
    } catch (error) {
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
      emit(const AuthRegisterSuccess());
    } catch (error) {
      emit(AuthFailure(message: _errorMessage(error)));
    }
  }

  Future<void> _onRestoreSessionRequested(
    RestoreSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final token = await tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        emit(const AuthUnauthenticated());
        return;
      }

      final user = await authRepository.getCurrentUser(token);
      emit(AuthAuthenticated(user: user));
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await tokenStorage.deleteToken();
        emit(const AuthUnauthenticated());
      } else {
        emit(
          const AuthSessionFailure(
            message: 'Không thể kiểm tra phiên đăng nhập',
          ),
        );
      }
    } catch (error) {
      emit(
        const AuthSessionFailure(
          message: 'Không thể khôi phục phiên đăng nhập',
        ),
      );
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
