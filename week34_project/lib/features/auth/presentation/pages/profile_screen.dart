import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../books/data/repositories/books_repository.dart';
import '../../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import '../../../members/data/repositories/members_repository.dart';
import '../../../reservations/data/repositories/reservations_repository.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../widgets/profile/librarian_counter_section.dart';
import '../widgets/profile/member_circulation_section.dart';
import '../widgets/profile/profile_header_card.dart';

class ProfileScreen extends StatelessWidget {
  final MembersRepository? membersRepository;
  final ReservationsRepository? reservationsRepository;
  final BorrowingSlipsRepository? borrowingSlipsRepository;
  final BooksRepository? booksRepository;

  const ProfileScreen({
    super.key,
    this.membersRepository,
    this.reservationsRepository,
    this.borrowingSlipsRepository,
    this.booksRepository,
  });

  static const errorRed = Color(0xFFDC2626);
  static const textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
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
        final isLibrarian = user.role.toUpperCase() == 'LIBRARIAN';

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. Thẻ thông tin người dùng chính
            ProfileHeaderCard(user: user),

            const SizedBox(height: 18),

            // 2. Nội dung theo vai trò
            if (isMember) ...[
              MemberCirculationSection(
                memberId: user.memberId,
                membersRepository: membersRepository,
                reservationsRepository: reservationsRepository,
                borrowingSlipsRepository: borrowingSlipsRepository,
              ),
              const SizedBox(height: 20),
            ] else if (isLibrarian) ...[
              LibrarianCounterSection(
                borrowingSlipsRepository: borrowingSlipsRepository,
                booksRepository: booksRepository,
                membersRepository: membersRepository,
              ),
              const SizedBox(height: 20),
            ],

            // 3. Nút Đăng xuất
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: errorRed,
                side: const BorderSide(color: Color(0xFFFECACA)),
                backgroundColor: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(vertical: 18),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 22),
              label: const Text(
                'Đăng xuất tài khoản',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
