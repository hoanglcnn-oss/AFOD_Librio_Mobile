import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/features/members/presentation/pages/borrowing_limit_screen.dart';
import 'package:week34_project/features/reservations/presentation/pages/my_reservations_screen.dart';

import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: Text('Chưa có thông tin tài khoản'));
        }

        final user = state.user;
        final isMember = user.role.toUpperCase() == 'MEMBER';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),

            const SizedBox(height: 16),

            Text(
              user.fullName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 24),

            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(user.email),
            ),

            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Số điện thoại'),
              subtitle: Text(user.phone),
            ),

            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Vai trò'),
              subtitle: Text(user.role),
            ),

            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Trạng thái tài khoản'),
              subtitle: Text(
                user.isActive ? 'Đang hoạt động' : 'Không hoạt động',
              ),
            ),

            if (isMember) ...[
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Hạn mức & điều kiện mượn'),
                subtitle: const Text(
                  'Theo dõi số sách đang mượn và điều kiện mượn thêm',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BorrowingLimitScreen(memberId: user.memberId),
                    ),
                  );
                },
              ),
              ListTile(
                key: const ValueKey('profile_my_reservations_tile'),
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('Đặt trước của tôi'),
                subtitle: const Text(
                  'Xem và quản lý các yêu cầu đặt trước sách',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MyReservationsScreen(memberId: user.memberId),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
            ],

            const SizedBox(height: 32),

            // Logout button
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}
