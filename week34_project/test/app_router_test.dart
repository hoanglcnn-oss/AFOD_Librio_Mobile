import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:week34_project/app/router/app_router.dart';
import 'package:week34_project/app/router/route_names.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/auth/data/models/user_profile.dart';
import 'package:week34_project/features/auth/presentation/pages/login_screen.dart';
import 'package:week34_project/features/home/presentation/pages/librarian_main_screen.dart';
import 'package:week34_project/features/home/presentation/pages/member_main_screen.dart';

import 'fake/fake_auth_repository.dart';
import 'fake/fake_token_storage.dart';

void main() {
  late FakeAuthRepository authRepository;
  late FakeTokenStorage tokenStorage;
  late AuthBloc authBloc;

  setUp(() {
    authRepository = FakeAuthRepository();
    tokenStorage = FakeTokenStorage();
    authBloc = AuthBloc(
      authRepository: authRepository,
      tokenStorage: tokenStorage,
    );
  });

  tearDown(() async {
    await authBloc.close();
  });

  Widget createTestRouterApp(GoRouter router) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  UserProfile makeUser({required String role}) {
    return UserProfile(
      id: 'user-01',
      memberId: 'mem-01',
      email: 'test@librio.vn',
      phone: '0901234567',
      fullName: 'Test User',
      role: role,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('AppRouter Navigation & Guards', () {
    testWidgets(
      'Khởi động ở trạng thái AuthRestoring -> hiển thị màn hình chờ (CircularProgressIndicator)',
      (tester) async {
        authBloc.emit(const AuthRestoring());
        final router = createAppRouter(authBloc);

        await tester.pumpWidget(createTestRouterApp(router));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(router.state.matchedLocation, AppRoutes.splash);
      },
    );

    testWidgets(
      'AuthUnauthenticated -> tự động redirect sang /login và hiển thị LoginScreen',
      (tester) async {
        authBloc.emit(const AuthUnauthenticated());
        final router = createAppRouter(authBloc);

        await tester.pumpWidget(createTestRouterApp(router));
        await tester.pump();
        await tester.pump();

        expect(router.state.matchedLocation, AppRoutes.login);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AuthAuthenticated với role MEMBER -> tự động redirect sang /member và hiển thị MemberMainScreen',
      (tester) async {
        authBloc.emit(AuthAuthenticated(user: makeUser(role: 'MEMBER')));
        final router = createAppRouter(authBloc);

        await tester.pumpWidget(createTestRouterApp(router));
        await tester.pump();
        await tester.pump();

        expect(router.state.matchedLocation, AppRoutes.memberHome);
        expect(find.byType(MemberMainScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AuthAuthenticated với role LIBRARIAN -> tự động redirect sang /librarian và hiển thị LibrarianMainScreen',
      (tester) async {
        authBloc.emit(AuthAuthenticated(user: makeUser(role: 'LIBRARIAN')));
        final router = createAppRouter(authBloc);

        await tester.pumpWidget(createTestRouterApp(router));
        await tester.pump();
        await tester.pump();

        expect(router.state.matchedLocation, AppRoutes.librarianHome);
        expect(find.byType(LibrarianMainScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AuthAuthenticated với role ADMIN -> tự động redirect sang /librarian',
      (tester) async {
        authBloc.emit(AuthAuthenticated(user: makeUser(role: 'ADMIN')));
        final router = createAppRouter(authBloc);

        await tester.pumpWidget(createTestRouterApp(router));
        await tester.pump();
        await tester.pump();

        expect(router.state.matchedLocation, AppRoutes.librarianHome);
      },
    );

    testWidgets(
      'Role Guard: MEMBER cố truy cập /librarian -> bị chặn và đưa về /member',
      (tester) async {
        authBloc.emit(AuthAuthenticated(user: makeUser(role: 'MEMBER')));
        final router = createAppRouter(authBloc);

        await tester.pumpWidget(createTestRouterApp(router));
        await tester.pump();
        await tester.pump();

        router.go(AppRoutes.librarianHome);
        await tester.pump();
        await tester.pump();

        expect(router.state.matchedLocation, AppRoutes.memberHome);
      },
    );

    testWidgets(
      'Đăng xuất: AuthAuthenticated chuyển sang AuthUnauthenticated -> tự động redirect về /login',
      (tester) async {
        authBloc.emit(AuthAuthenticated(user: makeUser(role: 'MEMBER')));
        final router = createAppRouter(authBloc);

        await tester.pumpWidget(createTestRouterApp(router));
        await tester.pump();
        await tester.pump();
        expect(router.state.matchedLocation, AppRoutes.memberHome);

        // Kích hoạt đăng xuất
        authBloc.emit(const AuthUnauthenticated());
        await tester.pump();
        await tester.pump();

        expect(router.state.matchedLocation, AppRoutes.login);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AuthSessionFailure -> hiển thị thông báo lỗi và nút Thử lại trên splash',
      (tester) async {
        authBloc.emit(const AuthSessionFailure(message: 'Lỗi kết nối phiên'));
        final router = createAppRouter(authBloc);

        await tester.pumpWidget(createTestRouterApp(router));
        await tester.pump();
        await tester.pump();

        expect(find.text('Lỗi kết nối phiên'), findsOneWidget);
        expect(find.text('Thử lại'), findsOneWidget);
      },
    );
  });
}
