import 'package:flutter/material.dart';

import '../../auth/presentation/profile_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../books/bloc/books_bloc.dart';
import '../../books/bloc/books_event.dart';
import '../../books/data/api_books_repository.dart';
import '../../books/presentation/books_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Librio Mobile' : 'Tài khoản'),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          BlocProvider(
            create: (_) =>
                BooksBloc(booksRepository: ApiBooksRepository())
                  ..add(const LoadBooks()),
            child: Builder(
              builder: (context) {
                return BooksScreen(
                  repository: context.read<BooksBloc>().booksRepository,
                );
              },
            ),
          ),
          const ProfileScreen(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Sách',
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
