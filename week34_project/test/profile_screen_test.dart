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
    testWidgets('MEMBER | Hiển thị Chỉ số lưu hành tài liệu', (
      tester,
    ) async {
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

      expect(find.text('Chỉ số lưu hành tài liệu'), findsOneWidget);
    });

    testWidgets('MEMBER | Nhấn vào Lượt mượn mở màn hình Lịch sử mượn trả', (
      tester,
    ) async {
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

      await tester.tap(find.text('Lượt mượn'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lịch sử mượn trả'), findsOneWidget);
    });

    testWidgets('LIBRARIAN | KHÔNG hiển thị Chỉ số lưu hành tài liệu', (
      tester,
    ) async {
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

      expect(find.text('Chỉ số lưu hành tài liệu'), findsNothing);
    });

    testWidgets('LIBRARIAN | Hiển thị Thông tin công tác & tài khoản', (
      tester,
    ) async {
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Thông tin công tác & tài khoản'), findsOneWidget);
      expect(find.text('Vai trò: Thủ thư vận hành'), findsOneWidget);
      expect(find.text('Đổi mật khẩu'), findsOneWidget);
      expect(find.text('Quy chế phục vụ thư viện'), findsOneWidget);
      expect(find.text('Phiên bản ứng dụng'), findsOneWidget);
    });

    testWidgets('ADMIN | KHÔNG hiển thị Chỉ số lưu hành tài liệu', (
      tester,
    ) async {
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

      expect(find.text('Chỉ số lưu hành tài liệu'), findsNothing);
    });

    testWidgets('Tablet (width >= 900) | Hiển thị bố cục 2 cột cho Profile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      expect(find.text('Nguyễn Văn Member'), findsOneWidget);
      expect(find.text('Đăng xuất tài khoản'), findsOneWidget);
      expect(find.text('Chỉ số lưu hành tài liệu'), findsOneWidget);
    });
  });
}
