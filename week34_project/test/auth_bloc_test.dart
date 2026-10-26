import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_event.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_token_storage.dart';

void main() {
  test('Login thành công phát Loading rồi Authenticated', () async {
    final tokenStorage = FakeTokenStorage();

    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      tokenStorage: tokenStorage,
    );

    final statesFuture = bloc.stream.take(2).toList();

    bloc.add(
      const LoginRequested(email: 'test@example.com', password: '123456'),
    );

    final states = await statesFuture;

    expect(states[0], isA<AuthLoading>());
    expect(states[1], isA<AuthAuthenticated>());

    final authenticated = states[1] as AuthAuthenticated;

    expect(authenticated.user.email, 'test@example.com');
    expect(authenticated.user.fullName, 'Test User');
    expect(tokenStorage.savedToken, 'fake_token');
    await bloc.close();
  });

  test('Login thất bại phát Loading rồi Failure', () async {
    final tokenStorage = FakeTokenStorage();

    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      tokenStorage: tokenStorage,
    );

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
      const AuthFailure(message: 'Đã xảy ra lỗi không xác định'),
    ]);

    await bloc.close();
  });

  test('Restore session thành công phát Loading rồi Authenticated', () async {
    final tokenStorage = FakeTokenStorage();

    await tokenStorage.saveToken('fake_token');

    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      tokenStorage: tokenStorage,
    );

    final statesFuture = bloc.stream.take(2).toList();

    bloc.add(const RestoreSessionRequested());

    final states = await statesFuture;

    expect(states[0], isA<AuthLoading>());
    expect(states[1], isA<AuthAuthenticated>());

    final authenticated = states[1] as AuthAuthenticated;

    expect(authenticated.user.email, 'test@example.com');
    expect(tokenStorage.savedToken, 'fake_token');

    await bloc.close();
  });
}
