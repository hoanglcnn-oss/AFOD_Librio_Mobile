import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import '../../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import '../../../borrowing_slips/presentation/pages/borrowing_slip_list_screen.dart';
import '../../../members/data/api_members_repository.dart';
import '../../../members/data/member_resolver.dart';
import '../../../members/data/members_repository.dart';
import '../../../reservations/presentation/pages/my_reservations_screen.dart';

class MyBorrowingsTab extends StatefulWidget {
  final VoidCallback onReturnSucceeded;
  final BorrowingSlipsRepository? borrowingSlipsRepository;
  final MembersRepository? membersRepository;

  const MyBorrowingsTab({
    super.key,
    required this.onReturnSucceeded,
    this.borrowingSlipsRepository,
    this.membersRepository,
  });

  @override
  State<MyBorrowingsTab> createState() => _MyBorrowingsTabState();
}

class _MyBorrowingsTabState extends State<MyBorrowingsTab> {
  late Future<String?> _memberIdFuture;

  @override
  void initState() {
    super.initState();
    _memberIdFuture = _resolveMemberId();
  }

  Future<String?> _resolveMemberId() async {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return null;
    }

    final user = authState.user;

    final resolver = MemberResolver(
      membersRepository: widget.membersRepository ?? ApiMembersRepository(),
    );

    return resolver.resolve(
      memberId: user.memberId,
      email: user.email,
      role: user.role,
    );
  }

  void _retry() {
    setState(() {
      _memberIdFuture = _resolveMemberId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _memberIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMessage('Không thể tải hồ sơ độc giả.');
        }

        final memberId = snapshot.data;

        if (memberId == null || memberId.isEmpty) {
          return _buildMessage('Không tìm thấy hồ sơ độc giả.');
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('my_reservations_entry_button'),
                      icon: const Icon(Icons.bookmark_outline, size: 18),
                      label: const Text('Đặt trước của tôi'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MyReservationsScreen(memberId: memberId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BorrowingSlipsScreen(
                memberId: memberId,
                repository: widget.borrowingSlipsRepository ??
                    ApiBorrowingSlipsRepository(),
                onReturnSucceeded: widget.onReturnSucceeded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _retry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
