import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../books/bloc/books_bloc.dart';
import '../../../books/bloc/books_event.dart';
import '../../../books/data/repositories/api_books_repository.dart';
import '../../../books/presentation/pages/books_screen.dart';
import '../../../borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import '../../../borrowing/slip_management/presentation/pages/borrowing_slip_list_screen.dart';
import '../../../members/data/repositories/api_members_repository.dart';

class MemberMainScreen extends StatefulWidget {
  const MemberMainScreen({super.key});

  @override
  State<MemberMainScreen> createState() => _MemberMainScreenState();
}

class _MemberMainScreenState extends State<MemberMainScreen> {
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
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
              title: Text(
                switch (_selectedIndex) {
                  1 => 'Sách đang mượn',
                  2 => 'Tài khoản',
                  _ => 'Librio Mobile',
                },
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
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
              ? _MemberBorrowingsTab(
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: Color(0xFF0D9488)),
              label: 'Sách',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark, color: Color(0xFF0D9488)),
              label: 'Đang mượn',
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

class _MemberBorrowingsTab extends StatefulWidget {
  final VoidCallback onReturnSucceeded;

  const _MemberBorrowingsTab({super.key, required this.onReturnSucceeded});

  @override
  State<_MemberBorrowingsTab> createState() => _MemberBorrowingsTabState();
}

class _MemberBorrowingsTabState extends State<_MemberBorrowingsTab> {
  late Future<String?> _memberIdFuture;

  @override
  void initState() {
    super.initState();
    _memberIdFuture = _resolveMemberId();
  }

  Future<String?> _resolveMemberId() async {
    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return null;
    }

    final user = authState.user;
    final repo = ApiMembersRepository();
    return repo.resolveMemberId(
      memberId: user.memberId,
      email: user.email,
      role: user.role,
    );
  }

  void _retry() {
    setState(() {
      _memberIdFuture = _resolveMemberId();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _memberIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMessage('Không thể tải hồ sơ độc giả.');
        }

        final memberId = snapshot.data;

        if (memberId == null || memberId.isEmpty) {
          return _buildMessage('Không tìm thấy hồ sơ độc giả.');
        }

        return BorrowingSlipsScreen(
          memberId: memberId,
          repository: ApiBorrowingSlipsRepository(),
          onReturnSucceeded: widget.onReturnSucceeded,
        );
      },
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _retry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
