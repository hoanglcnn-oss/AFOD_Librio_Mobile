import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/my_borrowings_bloc.dart';
import '../../bloc/my_borrowings_state.dart';
import '../../bloc/my_borrowings_event.dart';
import '../widgets/borrowing_card.dart';

class MyBorrowingsScreen extends StatelessWidget {
  final String memberId;
  final VoidCallback onReturnSucceeded;

  const MyBorrowingsScreen({
    super.key,
    required this.memberId,
    required this.onReturnSucceeded,
  });
  Future<void> _confirmReturn(BuildContext context, String borrowingId) async {
    final bloc = context.read<MyBorrowingsBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận trả sách'),
        content: const Text('Bạn có chắc muốn hoàn tất phiếu mượn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      bloc.add(ReturnBookRequested(borrowingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyBorrowingsBloc, MyBorrowingsState>(
      listenWhen: (previous, current) =>
          current is MyBorrowingsReturnSuccess ||
          current is MyBorrowingsReturnFailure,

      listener: (context, state) {
        if (state is MyBorrowingsReturnSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Trả sách thành công')));

          // Cập nhật tồn kho ở tab Books.
          onReturnSucceeded();

          // Tải lại phiếu mượn từ backend.
          context.read<MyBorrowingsBloc>().add(LoadMyBorrowings(memberId));
        }

        if (state is MyBorrowingsReturnFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },

      builder: (context, state) {
        // Giữ nguyên logic hiển thị danh sách ở bước 2.4.
        if (state is MyBorrowingsInitial || state is MyBorrowingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is MyBorrowingsFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      context.read<MyBorrowingsBloc>().add(
                        LoadMyBorrowings(memberId),
                      );
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final page = switch (state) {
          MyBorrowingsLoaded s => s.borrowingsPage,
          MyBorrowingsReturning s => s.borrowingsPage,
          MyBorrowingsReturnSuccess s => s.borrowingsPage,
          MyBorrowingsReturnFailure s => s.borrowingsPage,
          _ => null,
        };

        if (page != null) {
          final borrowings = page.borrowings;

          if (borrowings.isEmpty) {
            return const Center(child: Text('Bạn chưa có phiếu mượn sách nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: borrowings.length,
            itemBuilder: (context, index) {
              final borrowing = borrowings[index];

              final isReturning = state is MyBorrowingsReturning;
              final isCurrentItem =
                  isReturning && state.borrowingId == borrowing.id;

              return BorrowingCard(
                borrowing: borrowing,
                isReturning: isCurrentItem,
                onReturn: isReturning
                    ? null
                    : () => _confirmReturn(context, borrowing.id),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
