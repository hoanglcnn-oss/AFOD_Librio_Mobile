import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../borrowing/create_slip/presentation/pages/borrow_confirm_screen.dart';
import '../../../members/data/api_members_repository.dart';
import '../../../members/data/member_resolver.dart';
import '../../../borrowing/reservations/bloc/reservations_bloc.dart';
import '../../../borrowing/reservations/bloc/reservations_event.dart';
import '../../../borrowing/reservations/bloc/reservations_state.dart';
import '../../../borrowing/reservations/data/api_reservations_repository.dart';
import '../../../borrowing/reservations/data/reservations_repository.dart';
import '../../data/books_repository.dart';
import '../../data/models/book.dart';
import '../widgets/book_reserve_dialog.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  final BooksRepository repository;
  final ReservationsRepository? reservationsRepository;
  final ReservationsBloc? reservationsBloc;
  final MemberResolver? memberResolver;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    required this.repository,
    this.reservationsRepository,
    this.reservationsBloc,
    this.memberResolver,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<Book> _bookFuture;
  late final ReservationsBloc _reservationsBloc;
  bool _ownsBloc = false;

  @override
  void initState() {
    super.initState();
    _loadBook();

    if (widget.reservationsBloc != null) {
      _reservationsBloc = widget.reservationsBloc!;
    } else {
      _reservationsBloc = ReservationsBloc(
        reservationsRepository:
            widget.reservationsRepository ?? ApiReservationsRepository(),
      );
      _ownsBloc = true;
    }
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      _reservationsBloc.close();
    }
    super.dispose();
  }

  void _loadBook() {
    _bookFuture = widget.repository.getBookById(widget.bookId);
  }

  void _retry() {
    setState(_loadBook);
  }

  Future<void> _onReserveBook(Book book) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      AppToast.warning(context, 'Vui lòng đăng nhập để đặt trước sách');
      return;
    }

    final user = authState.user;
    if (user.role != 'MEMBER') {
      AppToast.warning(context, 'Chỉ độc giả mới có thể đặt trước sách');
      return;
    }

    final resolver = widget.memberResolver ??
        MemberResolver(membersRepository: ApiMembersRepository());

    final memberId = await resolver.resolve(
      memberId: user.memberId,
      email: user.email,
      role: user.role,
    );

    if (!mounted) return;

    if (memberId == null || memberId.isEmpty) {
      AppToast.error(context, 'Không tìm thấy hồ sơ độc giả');
      return;
    }

    final result = await showDialog<BookReserveDialogResult>(
      context: context,
      builder: (_) => BookReserveDialog(book: book),
    );

    if (result == null || !mounted) return;

    _reservationsBloc.add(
      CreateReservationRequested(
        memberId: memberId,
        bookId: book.id,
        notes: result.notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReservationsBloc>.value(
      value: _reservationsBloc,
      child: BlocConsumer<ReservationsBloc, ReservationsState>(
        listener: (context, state) {
          if (state is ReservationCreateSuccess) {
            AppToast.success(context, state.message);
            _retry();
          } else if (state is ReservationCreateFailure) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, resState) {
          final isReserving = resState is ReservationCreating;

          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết sách')),
            body: FutureBuilder<Book>(
              future: _bookFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final notFound =
                      error is DioException && error.response?.statusCode == 404;

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notFound
                              ? 'Không tìm thấy sách'
                              : 'Không thể tải chi tiết sách',
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _retry,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final book = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 220,
                      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? Image.network(
                              book.coverUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, error, stackTrace) {
                                return const Icon(Icons.menu_book, size: 80);
                              },
                            )
                          : const Icon(Icons.menu_book, size: 80),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    const SizedBox(height: 12),

                    Text('Tác giả: ${book.authorName}'),
                    Text('Thể loại: ${book.categoryName}'),
                    Text('ISBN: ${book.isbn}'),

                    const SizedBox(height: 16),

                    Text(
                      book.canBorrow
                          ? 'Còn ${book.copiesAvailable} / ${book.copiesTotal} cuốn'
                          : 'Hiện không thể mượn (đã hết bản khả dụng)',
                      style: TextStyle(
                        color: book.canBorrow
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text('Mô tả', style: Theme.of(context).textTheme.titleLarge),

                    const SizedBox(height: 8),

                    Text(
                      book.description.isEmpty
                          ? 'Chưa có mô tả'
                          : book.description,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('reserve_book_button'),
                            onPressed: isReserving
                                ? null
                                : () => _onReserveBook(book),
                            icon: isReserving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.bookmark_add_outlined),
                            label: Text(
                              isReserving ? 'Đang xử lý...' : 'Đặt trước',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey('borrow_book_button'),
                            onPressed: !book.canBorrow
                                ? null
                                : () async {
                                    final borrowed =
                                        await Navigator.of(context).push<bool>(
                                      MaterialPageRoute<bool>(
                                        builder: (_) =>
                                            BorrowConfirmScreen(book: book),
                                      ),
                                    );

                                    if (!context.mounted) return;

                                    if (borrowed == true) {
                                      Navigator.of(context).pop(true);
                                    } else {
                                      _retry();
                                    }
                                  },
                            child: const Text('Mượn sách'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
