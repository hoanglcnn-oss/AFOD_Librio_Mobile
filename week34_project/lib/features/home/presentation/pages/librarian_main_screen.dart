import 'package:flutter/material.dart';

import '../../../auth/presentation/pages/profile_screen.dart';

class LibrarianMainScreen extends StatefulWidget {
  const LibrarianMainScreen({super.key});

  @override
  State<LibrarianMainScreen> createState() => _LibrarianMainScreenState();
}

class _LibrarianMainScreenState extends State<LibrarianMainScreen> {
  int _selectedIndex = 0;

  static const _titles = ['Phiếu chờ duyệt', 'Quản lý phiếu mượn', 'Tài khoản'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _PendingSlipsPlaceholder(),
          _ManageSlipsPlaceholder(),
          ProfileScreen(),
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

class _PendingSlipsPlaceholder extends StatelessWidget {
  const _PendingSlipsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _FeaturePlaceholder(
      icon: Icons.fact_check_outlined,
      title: 'Phiếu chờ duyệt',
      description:
          'Danh sách phiếu PENDING_APPROVAL sẽ được '
          'tích hợp ở bước tiếp theo.',
    );
  }
}

class _ManageSlipsPlaceholder extends StatelessWidget {
  const _ManageSlipsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _FeaturePlaceholder(
      icon: Icons.assignment_outlined,
      title: 'Quản lý phiếu mượn',
      description:
          'Tra cứu phiếu, tiếp nhận trả sách '
          'và ghi nhận tiền phạt.',
    );
  }
}

class _FeaturePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeaturePlaceholder({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
