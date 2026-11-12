import 'package:flutter/material.dart';

import '../../../borrowing_slips/data/api_borrowing_slips_repository.dart';
import '../../../borrowing_slips/data/borrowing_slips_repository.dart';
import '../../../borrowing_slips/presentation/pages/manage_borrowing_slips_screen.dart';
import '../../data/api_borrowing_repository.dart';
import '../../data/borrowing_repository.dart';
import 'manage_single_borrowings_screen.dart';

class LibrarianManageScreen extends StatelessWidget {
  final BorrowingRepository borrowingRepository;
  final BorrowingSlipsRepository borrowingSlipsRepository;

  LibrarianManageScreen({
    super.key,
    BorrowingRepository? borrowingRepository,
    BorrowingSlipsRepository? borrowingSlipsRepository,
  })  : borrowingRepository = borrowingRepository ?? ApiBorrowingRepository(),
        borrowingSlipsRepository =
            borrowingSlipsRepository ?? ApiBorrowingSlipsRepository();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              tabs: [
                Tab(text: 'Mượn lẻ'),
                Tab(text: 'Phiếu nhiều sách'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ManageSingleBorrowingsScreen(repository: borrowingRepository),
                ManageBorrowingSlipsScreen(repository: borrowingSlipsRepository),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
