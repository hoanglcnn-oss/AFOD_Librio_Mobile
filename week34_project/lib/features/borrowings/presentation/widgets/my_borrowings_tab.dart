import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../members/data/api_members_repository.dart';
import '../../../members/data/member_resolver.dart';

import '../../bloc/my_borrowings_bloc.dart';
import '../../bloc/my_borrowings_event.dart';
import '../../data/api_borrowing_repository.dart';
import '../pages/my_borrowings_screen.dart';
import '../pages/borrowing_slip_list_screen.dart';

class MyBorrowingsTab extends StatefulWidget {
  final VoidCallback onReturnSucceeded;

  const MyBorrowingsTab({super.key, required this.onReturnSucceeded});

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

    final resolver = MemberResolver(membersRepository: ApiMembersRepository());

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

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Mượn lẻ'),
                  Tab(text: 'Phiếu nhiều sách'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    BlocProvider(
                      create: (_) => MyBorrowingsBloc(
                        borrowingRepository: ApiBorrowingRepository(),
                      )..add(LoadMyBorrowings(memberId)),
                      child: MyBorrowingsScreen(
                        memberId: memberId,
                        onReturnSucceeded: widget.onReturnSucceeded,
                      ),
                    ),
                    BorrowingSlipsScreen(
                      memberId: memberId,
                      repository: ApiBorrowingRepository(),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
