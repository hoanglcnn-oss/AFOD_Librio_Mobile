import 'package:flutter/material.dart';

import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import '../../../borrowing/slip_management/presentation/pages/borrowing_slip_list_screen.dart';
import '../../../borrowing/librarian_desk/presentation/pages/librarian_desk_screen.dart';

class LibrarianMainScreen extends StatefulWidget {
  const LibrarianMainScreen({super.key});

  @override
  State<LibrarianMainScreen> createState() => _LibrarianMainScreenState();
}

class _LibrarianMainScreenState extends State<LibrarianMainScreen> {
  int _selectedIndex = 0;

  static const _titles = ['Bàn trực', 'Quản lý phiếu mượn', 'Tài khoản'];
  late final ApiBorrowingSlipsRepository _borrowingSlipsRepository;

  @override
  void initState() {
    super.initState();
    _borrowingSlipsRepository = ApiBorrowingSlipsRepository();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          LibrarianDeskScreen(
            repository: _borrowingSlipsRepository,
            onNavigateToSlipsTab: () => setState(() => _selectedIndex = 1),
          ),
          BorrowingSlipsScreen(
            repository: _borrowingSlipsRepository,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF0FDFA),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon:
                  Icon(Icons.space_dashboard, color: Color(0xFF0D9488)),
              label: 'Bàn trực',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon:
                  Icon(Icons.receipt_long, color: Color(0xFF0D9488)),
              label: 'Phiếu mượn',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF0D9488)),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
