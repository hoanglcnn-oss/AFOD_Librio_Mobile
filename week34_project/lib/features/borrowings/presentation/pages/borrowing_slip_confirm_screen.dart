import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:week34_project/features/auth/bloc/auth_bloc.dart';
import 'package:week34_project/features/auth/bloc/auth_state.dart';
import 'package:week34_project/features/books/data/models/book.dart';
import 'package:week34_project/features/members/data/api_members_repository.dart';
import 'package:week34_project/features/members/data/member_resolver.dart';

import '../../bloc/borrowing_slip_bloc.dart';
import '../../bloc/borrowing_slip_event.dart';
import '../../bloc/borrowing_slip_state.dart';
import '../../data/api_borrowing_repository.dart';
import '../../data/models/create_borrowing_slip_request.dart';

class BorrowingSlipConfirmScreen extends StatelessWidget {
  final List<Book> books;

  const BorrowingSlipConfirmScreen({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BorrowingSlipBloc(borrowingRepository: ApiBorrowingRepository()),
      child: _SlipConfirmContent(books: books),
    );
  }
}

class _SlipConfirmContent extends StatefulWidget {
  final List<Book> books;

  const _SlipConfirmContent({required this.books});

  @override
  State<_SlipConfirmContent> createState() => _SlipConfirmContentState();
}

class _SlipConfirmContentState extends State<_SlipConfirmContent> {
  late final Future<String?> _memberIdFuture;
  late final Map<String, int> _quantities;

  int _days = 14;

  @override
  void initState() {
    super.initState();

    _quantities = {for (final book in widget.books) book.id: 1};

    _memberIdFuture = _resolveMember();
  }

  Future<String?> _resolveMember() async {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) return null;

    final user = authState.user;

    return MemberResolver(
      membersRepository: ApiMembersRepository(),
    ).resolve(memberId: user.memberId, email: user.email, role: user.role);
  }

  void _submit(String memberId) {
    final request = CreateBorrowingSlipRequest(
      memberId: memberId,
      expectedReturnDays: _days,
      items: [
        for (final book in widget.books)
          BorrowingSlipItemRequest(
            bookId: book.id,
            quantity: _quantities[book.id]!,
          ),
      ],
    );

    context.read<BorrowingSlipBloc>().add(CreateSlipRequested(request));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận phiếu mượn')),
      body: BlocBuilder<BorrowingSlipBloc, BorrowingSlipState>(
        builder: (context, state) {
          if (state is BorrowingSlipSuccess) {
            return _buildSuccess(state);
          }

          return FutureBuilder<String?>(
            future: _memberIdFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Không thể tra cứu hồ sơ độc giả'),
                );
              }

              final memberId = snapshot.data;

              if (memberId == null || memberId.isEmpty) {
                return const Center(
                  child: Text('Không tìm thấy hồ sơ độc giả liên kết'),
                );
              }

              return _buildForm(memberId, state);
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(String memberId, BorrowingSlipState state) {
    final submitting = state is BorrowingSlipSubmitting;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Sách đã chọn', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            for (final book in widget.books)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Còn ${book.copiesAvailable} cuốn'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Số lượng:'),
                          const Spacer(),
                          IconButton(
                            onPressed: submitting || _quantities[book.id]! <= 1
                                ? null
                                : () => setState(() {
                                    _quantities[book.id] =
                                        _quantities[book.id]! - 1;
                                  }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${_quantities[book.id]}'),
                          IconButton(
                            onPressed:
                                submitting ||
                                    _quantities[book.id]! >=
                                        book.copiesAvailable ||
                                    _quantities[book.id]! >= 5
                                ? null
                                : () => setState(() {
                                    _quantities[book.id] =
                                        _quantities[book.id]! + 1;
                                  }),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Text(
              'Thời hạn mượn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            DropdownButton<int>(
              value: _days,
              isExpanded: true,
              onChanged: submitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _days = value);
                      }
                    },
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 ngày')),
                DropdownMenuItem(value: 14, child: Text('14 ngày')),
                DropdownMenuItem(value: 30, child: Text('30 ngày')),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'Phiếu sẽ được gửi để chờ duyệt. '
              'Sách chưa được mượn ngay sau khi gửi.',
            ),

            if (state is BorrowingSlipFailure) ...[
              const SizedBox(height: 12),
              Text(
                state.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),

            FilledButton(
              onPressed: submitting ? null : () => _submit(memberId),
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi phiếu mượn'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BorrowingSlipSuccess state) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Đã gửi phiếu mượn!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text('Mã phiếu: ${state.slip.slipNumber}'),
              const SizedBox(height: 8),
              const Text('Trạng thái: Chờ duyệt', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('${state.slip.items.length} đầu sách'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quay về danh sách sách'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
