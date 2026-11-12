import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_toast.dart';

import '../../bloc/my_borrowings_bloc.dart';
import '../../bloc/my_borrowings_state.dart';
import '../../bloc/my_borrowings_event.dart';
import '../widgets/borrowing_card.dart';

class MyBorrowingsScreen extends StatelessWidget {
  final String memberId;
  final VoidCallback onReturnSucceeded;
  final bool allowActions;

  const MyBorrowingsScreen({
    super.key,
    required this.memberId,
    required this.onReturnSucceeded,
    this.allowActions = false,
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

  Future<void> _confirmRenew(BuildContext context, String borrowingId) async {
    final bloc = context.read<MyBorrowingsBloc>();

    int selectedDays = 7;

    final extraDays = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Gia hạn mượn sách'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn số ngày muốn gia hạn:'),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    initialValue: selectedDays,
                    items: [
                      for (int day = 1; day <= 14; day++)
                        DropdownMenuItem(value: day, child: Text('$day ngày')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedDays = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  const Text('Mỗi phiếu được gia hạn tối đa 2 lần.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedDays);
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );

    if (extraDays != null && context.mounted) {
      bloc.add(
        RenewBorrowingRequested(borrowingId: borrowingId, extraDays: extraDays),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyBorrowingsBloc, MyBorrowingsState>(
      listenWhen: (previous, current) =>
          current is MyBorrowingsReturnSuccess ||
          current is MyBorrowingsReturnFailure ||
          current is MyBorrowingsRenewSuccess ||
          current is MyBorrowingsRenewFailure,

      listener: (context, state) {
        if (state is MyBorrowingsReturnSuccess) {
          AppToast.success(context, 'Trả sách thành công');

          // Cập nhật tồn kho ở tab Books.
          onReturnSucceeded();

          // Tải lại phiếu mượn từ backend.
          context.read<MyBorrowingsBloc>().add(LoadMyBorrowings(memberId));
        }

        if (state is MyBorrowingsReturnFailure) {
          AppToast.error(context, state.message);
        }
        if (state is MyBorrowingsRenewSuccess) {
          AppToast.success(context, 'Gia hạn sách thành công');

          // Tải lại từ backend để nhận dueDate và renewCount mới.
          context.read<MyBorrowingsBloc>().add(LoadMyBorrowings(memberId));
        }

        if (state is MyBorrowingsRenewFailure) {
          AppToast.error(context, state.message);
        }
      },

      builder: (context, state) {
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

          MyBorrowingsRenewing s => s.borrowingsPage,
          MyBorrowingsRenewSuccess s => s.borrowingsPage,
          MyBorrowingsRenewFailure s => s.borrowingsPage,

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

              // Xác định BLoC đang xử lý Return hay Renew
              final isReturning = state is MyBorrowingsReturning;
              final isRenewing = state is MyBorrowingsRenewing;

              // Khóa các thao tác khi có request đang chạy
              final isBusy = isReturning || isRenewing;

              // Xác định phiếu nào đang được xử lý
              final isCurrentReturn =
                  isReturning && state.borrowingId == borrowing.id;

              final isCurrentRenew =
                  isRenewing && state.borrowingId == borrowing.id;

              return BorrowingCard(
                borrowing: borrowing,
                isBusy: isBusy,
                isReturning: isCurrentReturn,
                isRenewing: isCurrentRenew,
                onReturn: allowActions
                    ? () => _confirmReturn(context, borrowing.id)
                    : null,
                onRenew: allowActions
                    ? () => _confirmRenew(context, borrowing.id)
                    : null,
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
