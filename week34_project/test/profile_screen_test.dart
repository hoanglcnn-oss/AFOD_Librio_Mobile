import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/auth/presentation/pages/profile_screen.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_token_storage.dart';

void main() {
  late AuthBloc authBloc;

  Widget createApp(AuthState state) {
    authBloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      tokenStorage: FakeTokenStorage(),
    )..emit(state);

    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const Scaffold(body: ProfileScreen()),
      ),
    );
  }

  tearDown(() async {
    await authBloc.close();
  });

  group('ProfileScreen', () {
    testWidgets('MEMBER | Hiển thị mục Hạn mức & điều kiện mượn', (tester) async {
      final user = UserProfile(
        id: 'user-01',
        email: 'member@example.com',
        fullName: 'Nguyễn Văn Member',
        phone: '0901234567',
        role: 'MEMBER',
        isActive: true,
        memberId: 'mem-01',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(createApp(AuthAuthenticated(user: user)));
      await tester.pumpAndSettle();

      expect(find.text('Hạn mức & điều kiện mượn'), findsOneWidget);
      expect(
        find.text('Theo dõi số sách đang mượn và điều kiện mượn thêm'),
        findsOneWidget,
      );
    });

    testWidgets('LIBRARIAN | KHÔNG hiển thị mục Hạn mức & điều kiện mượn', (tester) async {
      final user = UserProfile(
        id: 'user-02',
        email: 'lib@example.com',
        fullName: 'Thủ thư A',
        phone: '0907654321',
        role: 'LIBRARIAN',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(createApp(AuthAuthenticated(user: user)));
      await tester.pumpAndSettle();

      expect(find.text('Hạn mức & điều kiện mượn'), findsNothing);
    });

    testWidgets('ADMIN | KHÔNG hiển thị mục Hạn mức & điều kiện mượn', (tester) async {
      final user = UserProfile(
        id: 'user-03',
        email: 'admin@example.com',
        fullName: 'Admin B',
        phone: '0901112223',
        role: 'ADMIN',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(createApp(AuthAuthenticated(user: user)));
      await tester.pumpAndSettle();

      expect(find.text('Hạn mức & điều kiện mượn'), findsNothing);
    });
  });
}
