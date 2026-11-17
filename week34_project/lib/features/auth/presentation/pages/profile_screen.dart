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
    const primaryNavy = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);
    const borderHairline = Color(0xFFE2E8F0);
    const tealAccent = Color(0xFF0D9488);
    const tealBg = Color(0xFFF0FDFA);
    const errorRed = Color(0xFFDC2626);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(
            child: Text(
              'Chưa có thông tin tài khoản',
              style: TextStyle(color: textMuted),
            ),
          );
        }

        final user = state.user;
        final isMember = user.role.toUpperCase() == 'MEMBER';

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // 1. Thẻ thông tin cá nhân chính (User Header Card)
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderHairline),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: tealBg,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName.trim().split(' ').last[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: tealAccent,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            user.isActive
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 18,
                            color: user.isActive
                                ? const Color(0xFF10B981)
                                : errorRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderHairline),
                      ),
                      child: Text(
                        switch (user.role.toUpperCase()) {
                          'MEMBER' => 'Độc giả',
                          'LIBRARIAN' => 'Thủ thư',
                          'ADMIN' => 'Quản trị viên',
                          _ => user.role,
                        },
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Nhóm Dịch vụ Độc giả (Chỉ hiển thị cho MEMBER)
            if (isMember) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'DỊCH VỤ ĐỘC GIẢ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: textMuted,
                  ),
                ),
              ),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: borderHairline),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Mục 1: Đặt trước của tôi (Đưa lên vị trí ưu tiên số 1)
                    ListTile(
                      key: const ValueKey('profile_my_reservations_tile'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tealBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bookmark_outline_rounded,
                          color: tealAccent,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Đặt trước của tôi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryNavy,
                        ),
                      ),
                      subtitle: const Text(
                        'Xem và quản lý các yêu cầu đặt trước sách',
                        style: TextStyle(fontSize: 12.5, color: textMuted),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MyReservationsScreen(memberId: user.memberId),
                          ),
                        );
                      },
                    ),

                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 68,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),

                    // Mục 2: Hạn mức & điều kiện mượn
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_stories_outlined,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Hạn mức & điều kiện mượn',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryNavy,
                        ),
                      ),
                      subtitle: const Text(
                        'Theo dõi số sách đang mượn và điều kiện mượn thêm',
                        style: TextStyle(fontSize: 12.5, color: textMuted),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BorrowingLimitScreen(memberId: user.memberId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 3. Nhóm Thông tin tài khoản chi tiết
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'THÔNG TIN TÀI KHOẢN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textMuted,
                ),
              ),
            ),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderHairline),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.email_outlined, color: textMuted, size: 20),
                    title: const Text('Email', style: TextStyle(fontSize: 12, color: textMuted)),
                    subtitle: Text(
                      user.email,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryNavy),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, indent: 52, color: Color(0xFFF1F5F9)),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.phone_outlined, color: textMuted, size: 20),
                    title: const Text('Số điện thoại', style: TextStyle(fontSize: 12, color: textMuted)),
                    subtitle: Text(
                      user.phone.isNotEmpty ? user.phone : 'Chưa cập nhật',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryNavy),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, indent: 52, color: Color(0xFFF1F5F9)),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.badge_outlined, color: textMuted, size: 20),
                    title: const Text('Vai trò', style: TextStyle(fontSize: 12, color: textMuted)),
                    subtitle: Text(
                      user.role,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryNavy),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, indent: 52, color: Color(0xFFF1F5F9)),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.verified_user_outlined, color: textMuted, size: 20),
                    title: const Text('Trạng thái tài khoản', style: TextStyle(fontSize: 12, color: textMuted)),
                    subtitle: Text(
                      user.isActive ? 'Đang hoạt động' : 'Không hoạt động',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: user.isActive ? const Color(0xFF10B981) : errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 4. Nút Đăng xuất (Touch-friendly & Clean)
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: errorRed,
                side: const BorderSide(color: Color(0xFFFECACA)),
                backgroundColor: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
