import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/members/data/api_members_repository.dart';
import 'package:week34_project/features/members/data/member_resolver.dart';

import '../../bloc/borrowing_bloc.dart';
import '../../bloc/borrowing_event.dart';
import '../../bloc/borrowing_state.dart';
import '../../data/api_borrowing_repository.dart';
import '../../data/models/create_borrowing_request.dart';
import '../widgets/borrow_confirm_card.dart';
import 'borrow_result_screen.dart';

class BorrowConfirmScreen extends StatelessWidget {
  final Book book;

  const BorrowConfirmScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BorrowingBloc(borrowingRepository: ApiBorrowingRepository()),
      child: _BorrowConfirmContent(book: book),
    );
  }
}

class _BorrowConfirmContent extends StatefulWidget {
  final Book book;

  const _BorrowConfirmContent({required this.book});

  @override
  State<_BorrowConfirmContent> createState() => _BorrowConfirmContentState();
}

class _BorrowConfirmContentState extends State<_BorrowConfirmContent> {
  late final MemberResolver _resolver;
  late Future<String?> _memberIdFuture;

  @override
  void initState() {
    super.initState();

    _resolver = MemberResolver(membersRepository: ApiMembersRepository());

    _memberIdFuture = _resolveMember();
  }

  Future<String?> _resolveMember() async {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      debugPrint('MEMBER: user not authenticated');
      return null;
    }

    final user = authState.user;

    debugPrint('MEMBER: role=${user.role}');
    debugPrint('MEMBER: hasMemberId=${user.memberId != null}');

    final result = await _resolver.resolve(
      memberId: user.memberId,
      email: user.email,
      role: user.role,
    );

    debugPrint('MEMBER: resolved=${result != null}');

    return result;
  }

  void _retryResolve() {
    setState(() {
      _memberIdFuture = _resolveMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BorrowingBloc, BorrowingState>(
      listener: (context, state) {
        if (state is BorrowingSuccess) {
          Navigator.of(context)
              .push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      BorrowResultScreen(borrowing: state.borrowing),
                ),
              )
              .then((_) {
                if (!context.mounted) return;

                Navigator.of(context).pop(true);
              });
        }

        if (state is BorrowingFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Xác nhận mượn sách')),
        body: FutureBuilder<String?>(
          future: _memberIdFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildResolveError('Không thể tra cứu hồ sơ độc giả.');
            }

            final memberId = snapshot.data;

            if (memberId == null || memberId.isEmpty) {
              return _buildResolveError(
                'Không tìm thấy hồ sơ độc giả liên kết '
                'với tài khoản này.',
              );
            }

            return _buildConfirmation(memberId);
          },
        ),
      ),
    );
  }

  Widget _buildResolveError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _retryResolve,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation(String memberId) {
    return BlocBuilder<BorrowingBloc, BorrowingState>(
      builder: (context, state) {
        final isSubmitting = state is BorrowingSubmitting;
        final isSuccess = state is BorrowingSuccess;

        return BorrowConfirmCard(
          book: widget.book,
          memberId: memberId,
          isSubmitting: isSubmitting,
          isSuccess: isSuccess,
          onConfirm: () {
            context.read<BorrowingBloc>().add(
              BorrowBookRequested(
                CreateBorrowingRequest(
                  memberId: memberId,
                  bookId: widget.book.id,
                  durationDays: 14,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
