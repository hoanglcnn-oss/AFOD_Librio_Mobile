import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/forgot_password_bloc.dart';
import 'package:week34_project/features/auth/bloc/forgot_password_event.dart';
import 'package:week34_project/features/auth/bloc/forgot_password_state.dart';

import 'fake/fake_auth_repository.dart';

void main() {
  group('ForgotPasswordBloc', () {
    test('Submit emits Loading -> Success', () async {
      final repository = FakeAuthRepository();
      final bloc = ForgotPasswordBloc(authRepository: repository);

      final states = <ForgotPasswordState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const SubmitForgotPassword('user@example.com'));

      await bloc.stream.firstWhere((state) => state is ForgotPasswordSuccess);

      expect(states, [
        isA<ForgotPasswordLoading>(),
        isA<ForgotPasswordSuccess>(),
      ]);
      expect(repository.forgotPasswordCallCount, 1);

      await subscription.cancel();
      await bloc.close();
    });

    test('Submit emits Loading -> Failure', () async {
      final repository = FakeAuthRepository()..shouldFailForgotPassword = true;

      final bloc = ForgotPasswordBloc(authRepository: repository);

      final states = <ForgotPasswordState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const SubmitForgotPassword('user@example.com'));

      await bloc.stream.firstWhere((state) => state is ForgotPasswordFailure);

      expect(states, [
        isA<ForgotPasswordLoading>(),
        isA<ForgotPasswordFailure>(),
      ]);
      expect(repository.forgotPasswordCallCount, 1);

      await subscription.cancel();
      await bloc.close();
    });
    test('Email rỗng không gọi Repository', () async {
      final repository = FakeAuthRepository();
      final bloc = ForgotPasswordBloc(authRepository: repository);

      bloc.add(const SubmitForgotPassword('   '));

      await bloc.stream.firstWhere((state) => state is ForgotPasswordFailure);

      expect(repository.forgotPasswordCallCount, 0);

      await bloc.close();
    });
  });
}
