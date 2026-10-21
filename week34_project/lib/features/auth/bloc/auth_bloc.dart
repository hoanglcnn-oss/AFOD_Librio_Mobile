import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../data/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    // Đăng ký xử lý LoginRequested bằng on<LoginRequested>()
    on<LoginRequested>(_onLoginRequested);
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
      // Sử dụng thông báo lỗi giả lập.
      emit(const AuthFailure(message: 'Sai tài khoản hoặc mật khẩu (giả lập)'));
    }
  }
}
