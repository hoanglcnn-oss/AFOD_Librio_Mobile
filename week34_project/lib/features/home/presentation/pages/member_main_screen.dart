import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../books/bloc/books_bloc.dart';
import '../../../books/bloc/books_event.dart';
import '../../../books/data/api_books_repository.dart';
import '../../../books/presentation/pages/books_screen.dart';
import '../../../borrowing/reservations/presentation/pages/my_reservations_screen.dart';
import '../../../borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import '../../../borrowing/slip_management/presentation/pages/borrowing_slip_list_screen.dart';
import '../../../members/data/api_members_repository.dart';
import '../../../members/data/member_resolver.dart';

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

      bottomNavigationBar: NavigationBar(
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Sách',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Đang mượn',
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

class _MemberBorrowingsTab extends StatefulWidget {
  final VoidCallback onReturnSucceeded;

  const _MemberBorrowingsTab({
    super.key,
    required this.onReturnSucceeded,
  });

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

    final resolver = MemberResolver(
      membersRepository: ApiMembersRepository(),
    );

    return resolver.resolve(
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('my_reservations_entry_button'),
                      icon: const Icon(Icons.bookmark_outline, size: 18),
                      label: const Text('Đặt trước của tôi'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MyReservationsScreen(memberId: memberId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BorrowingSlipsScreen(
                memberId: memberId,
                repository: ApiBorrowingSlipsRepository(),
                onReturnSucceeded: widget.onReturnSucceeded,
              ),
            ),
          ],
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
