import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/my_borrowings_bloc.dart';
import '../../bloc/my_borrowings_state.dart';
import '../widgets/borrowing_card.dart';

class MyBorrowingsScreen extends StatelessWidget {
  const MyBorrowingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyBorrowingsBloc, MyBorrowingsState>(
      builder: (context, state) {
        if (state is MyBorrowingsInitial || state is MyBorrowingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MyBorrowingsFailure) {
          return Center(child: Text(state.message));
        }

        if (state is MyBorrowingsLoaded) {
          final borrowings = state.borrowingsPage.borrowings;

          if (borrowings.isEmpty) {
            return const Center(child: Text('Bạn chưa có phiếu mượn sách nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: borrowings.length,
            itemBuilder: (context, index) {
              final borrowing = borrowings[index];
              //kéo từ borrowing_card.dart
              return BorrowingCard(borrowing: borrowing);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
