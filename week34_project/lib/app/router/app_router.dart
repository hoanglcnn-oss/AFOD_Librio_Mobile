import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/data/models/app_role.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/home/presentation/pages/librarian_main_screen.dart';
import '../../features/home/presentation/pages/member_main_screen.dart';
import 'route_names.dart';

/// Lắng nghe Stream của [AuthBloc] và thông báo cho [GoRouter] thực hiện redirect
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Khởi tạo [GoRouter] nền tảng liên kết với trạng thái xác thực và vai trò của [AuthBloc]
GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;

      // 1. Đang khởi tạo hoặc khôi phục phiên đăng nhập
      if (authState is AuthInitial || authState is AuthRestoring) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // 2. Lỗi khôi phục phiên: giữ ở splash để xem thông báo và nút "Thử lại"
      if (authState is AuthSessionFailure) {
        return (location == AppRoutes.splash || location == AppRoutes.login)
            ? null
            : AppRoutes.splash;
      }

      // 3. Chưa đăng nhập
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.forgotPassword;

      if (!isAuthenticated) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      // 4. Đã đăng nhập: phân luồng theo vai trò người dùng
      final role = AppRole.fromString(authState.user.role);
      final roleTarget = switch (role) {
        AppRole.member => AppRoutes.memberHome,
        AppRole.librarian || AppRole.admin => AppRoutes.librarianHome,
        AppRole.unknown => AppRoutes.unsupportedRole,
      };

      // Đang ở luồng auth hoặc splash thì chuyển thẳng đến màn hình chính của vai trò đó
      if (isAuthRoute || location == AppRoutes.splash) {
        return roleTarget;
      }

      // 5. Bảo vệ phân quyền màn hình (Role-based Guards)
      if (location.startsWith(AppRoutes.librarianHome) &&
          role == AppRole.member) {
        return AppRoutes.memberHome;
      }

      if (location.startsWith(AppRoutes.memberHome) &&
          (role == AppRole.librarian || role == AppRole.admin)) {
        return AppRoutes.librarianHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) {
          final authState = authBloc.state;
          if (authState is AuthSessionFailure) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authState.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          authBloc.add(const RestoreSessionRequested());
                        },
                        child: const Text('Thử lại'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          context.go(AppRoutes.login);
                        },
                        child: const Text('Đến màn hình đăng nhập'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberHome,
        builder: (context, state) => const MemberMainScreen(),
      ),
      GoRoute(
        path: AppRoutes.librarianHome,
        builder: (context, state) => const LibrarianMainScreen(),
      ),
      GoRoute(
        path: AppRoutes.unsupportedRole,
        builder: (context, state) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Vai trò tài khoản chưa được hỗ trợ.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      authBloc.add(const LogoutRequested());
                    },
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
