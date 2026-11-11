import 'package:flutter/material.dart';

import '../../data/borrowing_repository.dart';
import 'manage_borrowing_slips_screen.dart';
import 'manage_single_borrowings_screen.dart';

class LibrarianManageScreen extends StatelessWidget {
  final BorrowingRepository repository;

  const LibrarianManageScreen({super.key, required this.repository});

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
                ManageSingleBorrowingsScreen(repository: repository),
                ManageBorrowingSlipsScreen(repository: repository),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

