import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../books/data/models/book.dart';

import '../bloc/borrowing_bloc.dart';
import '../bloc/borrowing_event.dart';
import '../bloc/borrowing_state.dart';
import '../data/api_borrowing_repository.dart';
import '../data/models/create_borrowing_request.dart';
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

class _BorrowConfirmContent extends StatelessWidget {
  final Book book;

  const _BorrowConfirmContent({required this.book});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    final memberId = authState is AuthAuthenticated
        ? authState.user.memberId
        : null;

    final hasMemberId = memberId != null && memberId.trim().isNotEmpty;

    return BlocListener<BorrowingBloc, BorrowingState>(
      listener: (context, state) {
        if (state is BorrowingSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BorrowResultScreen(borrowing: state.borrowing),
            ),
          );
        }

        if (state is BorrowingFailure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Xác nhận mượn sách')),
        body: BlocBuilder<BorrowingBloc, BorrowingState>(
          builder: (context, state) {
            final isSubmitting = state is BorrowingSubmitting;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text('Tác giả: ${book.authorName}'),
                Text('Số lượng còn: ${book.copiesAvailable}'),

                const SizedBox(height: 24),

                const ListTile(
                  leading: Icon(Icons.event),
                  title: Text('Thời hạn mượn'),
                  subtitle: Text('14 ngày'),
                ),

                if (!hasMemberId) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa xác định được hồ sơ độc giả '
                    'của tài khoản hiện tại.',
                  ),
                ],

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: isSubmitting || !book.canBorrow || !hasMemberId
                      ? null
                      : () {
                          final validMemberId = memberId;

                          if (validMemberId.trim().isEmpty) {
                            return;
                          }

                          context.read<BorrowingBloc>().add(
                            BorrowBookRequested(
                              CreateBorrowingRequest(
                                memberId: validMemberId,
                                bookId: book.id,
                                durationDays: 14,
                              ),
                            ),
                          );
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xác nhận mượn'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
