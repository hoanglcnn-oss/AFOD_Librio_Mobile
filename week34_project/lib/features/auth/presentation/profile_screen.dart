import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

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
          ],
        );
      },
    );
  }
}
