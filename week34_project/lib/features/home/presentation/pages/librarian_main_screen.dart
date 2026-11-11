import 'package:flutter/material.dart';

import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../borrowings/data/api_borrowing_repository.dart';
import '../../../borrowings/presentation/pages/librarian_manage_screen.dart';
import '../../../borrowings/presentation/pages/pending_borrowing_slips_screen.dart';

class LibrarianMainScreen extends StatefulWidget {
  const LibrarianMainScreen({super.key});

  @override
  State<LibrarianMainScreen> createState() => _LibrarianMainScreenState();
}

class _LibrarianMainScreenState extends State<LibrarianMainScreen> {
  int _selectedIndex = 0;

  static const _titles = ['Phiếu chờ duyệt', 'Quản lý phiếu mượn', 'Tài khoản'];
  late final ApiBorrowingRepository _borrowingRepository;

  @override
  void initState() {
    super.initState();
    _borrowingRepository = ApiBorrowingRepository();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PendingBorrowingSlipsScreen(repository: _borrowingRepository),
          LibrarianManageScreen(repository: _borrowingRepository),
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
            icon: Icon(Icons.pending_actions_outlined),
            selectedIcon: Icon(Icons.pending_actions),
            label: 'Chờ duyệt',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Quản lý phiếu',
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
