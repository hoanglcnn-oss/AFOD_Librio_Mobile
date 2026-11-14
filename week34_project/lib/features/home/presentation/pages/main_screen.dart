import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:week34_project/features/auth/presentation/pages/profile_screen.dart';
import 'package:week34_project/features/books/bloc/books_bloc.dart';
import 'package:week34_project/features/books/bloc/books_event.dart';
import 'package:week34_project/features/books/data/api_books_repository.dart';
import 'package:week34_project/features/books/presentation/pages/books_screen.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/my_borrowings_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _hasOpenedBorrowings = false;
  bool _borrowingsNeedsRefresh = false;
  int _borrowingsRefreshVersion = 0;
  late final BooksBloc _booksBloc;

  @override
  void initState() {
    super.initState();

    _booksBloc = BooksBloc(booksRepository: ApiBooksRepository())
      ..add(const LoadBooks());
  }

  @override
  void dispose() {
    _booksBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(switch (_selectedIndex) {
                1 => 'Sách đang mượn',
                2 => 'Tài khoản',
                _ => 'Librio Mobile',
              }),
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Index 0: Books
          BlocProvider.value(
            value: _booksBloc,
            child: BooksScreen(
              repository: _booksBloc.booksRepository,
              onBorrowSucceeded: () {
                setState(() {
                  _borrowingsNeedsRefresh = true;
                });
              },
            ),
          ),

          // Index 1: My Borrowings
          _hasOpenedBorrowings
              ? MyBorrowingsTab(
                  key: ValueKey(_borrowingsRefreshVersion),
                  onReturnSucceeded: () {
                    _booksBloc.add(const LoadBooks());
                  },
                )
              : const SizedBox.shrink(),
          // Index 2: Profile
          const ProfileScreen(),
        ],
      ),

      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;

            if (index == 1) {
              _hasOpenedBorrowings = true;

              if (_borrowingsNeedsRefresh) {
                _borrowingsRefreshVersion++;
                _borrowingsNeedsRefresh = false;
              }
            }
          });
        },
      ),
    );
  }
}
