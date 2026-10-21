import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_event.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/fake_auth_repository.dart';

void main() {
  test('Login thành công phát Loading rồi Success', () async {
    final bloc = AuthBloc(authRepository: FakeAuthRepository());

    // Tạo Future ghi nhận 2 state được phát ra.
    final statesFuture = bloc.stream.take(2).toList();

    // Gửi LoginRequested với tài khoản giả lập hợp lệ.
    bloc.add(
      const LoginRequested(email: 'test@example.com', password: '123456'),
    );

    // Chờ kết quả.
    final states = await statesFuture;

    // Kiểm tra thứ tự các state.
    expect(states, [
      const AuthLoading(),
      const AuthSuccess(message: 'Đăng nhập thành công'),
    ]);

    await bloc.close();
  });

  test('Login thất bại phát Loading rồi Failure', () async {
    final bloc = AuthBloc(authRepository: FakeAuthRepository());

    // Lắng nghe 2 state tiếp theo.
    final statesFuture = bloc.stream.take(2).toList();

    // Gửi LoginRequested với mật khẩu sai.
    bloc.add(
      const LoginRequested(
        email: 'test@example.com',
        password: 'wrong-password',
      ),
    );

    // Chờ statesFuture.
    final states = await statesFuture;

    // Kiểm tra thứ tự AuthLoading → AuthFailure.
    expect(states, [
      const AuthLoading(),
      const AuthFailure(message: 'Sai tài khoản hoặc mật khẩu (giả lập)'),
    ]);

    await bloc.close();
  });
}
