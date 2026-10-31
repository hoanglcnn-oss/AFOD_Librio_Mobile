import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:week34_project/features/auth/presentation/pages/profile_screen.dart';
import 'package:week34_project/features/books/bloc/books_bloc.dart';
import 'package:week34_project/features/books/bloc/books_event.dart';
import 'package:week34_project/features/books/data/api_books_repository.dart';
import 'package:week34_project/features/books/presentation/pages/books_screen.dart';

import '../widgets/home_bottom_nav_bar.dart';

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
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
