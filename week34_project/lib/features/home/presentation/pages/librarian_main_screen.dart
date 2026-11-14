import 'package:flutter/material.dart';

import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import 'librarian_manage_screen.dart';
import '../../../borrowing/approve_slip/presentation/pages/pending_borrowing_slips_screen.dart';

class LibrarianMainScreen extends StatefulWidget {
  const LibrarianMainScreen({super.key});

  @override
  State<LibrarianMainScreen> createState() => _LibrarianMainScreenState();
}

class _LibrarianMainScreenState extends State<LibrarianMainScreen> {
  int _selectedIndex = 0;

  static const _titles = ['Phiếu chờ duyệt', 'Quản lý phiếu mượn', 'Tài khoản'];
  late final ApiBorrowingSlipsRepository _borrowingSlipsRepository;

  @override
  void initState() {
    super.initState();
    _borrowingSlipsRepository = ApiBorrowingSlipsRepository();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PendingBorrowingSlipsScreen(repository: _borrowingSlipsRepository),
          LibrarianManageScreen(
            borrowingSlipsRepository: _borrowingSlipsRepository,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_turned_in_outlined),
            selectedIcon: Icon(Icons.assignment_turned_in),
            label: 'Chờ duyệt',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Phiếu mượn',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
