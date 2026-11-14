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
  bool _isDescriptionExpanded = false;

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

          return FutureBuilder<Book>(
            future: _bookFuture,
            builder: (context, snapshot) {
              final isDone = snapshot.connectionState == ConnectionState.done;
              final hasData = isDone && !snapshot.hasError && snapshot.data != null;
              final book = snapshot.data;

              return Scaffold(
                backgroundColor: const Color(0xFFF7FAFD),
                appBar: AppBar(
                  title: const Text(
                    'Chi tiết sách',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF17263D),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF17263D),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1.0),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFCDD8E5),
                    ),
                  ),
                ),
                body: _buildBody(snapshot),
                bottomNavigationBar: hasData && book != null
                    ? _buildStickyActionBar(book, isReserving)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<Book> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      final error = snapshot.error;
      final notFound =
          error is DioException && error.response?.statusCode == 404;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                notFound ? Icons.search_off_outlined : Icons.cloud_off_outlined,
                size: 56,
                color: const Color(0xFF566B87),
              ),
              const SizedBox(height: 16),
              Text(
                notFound
                    ? 'Không tìm thấy sách'
                    : 'Không thể tải chi tiết sách',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17263D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A488E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final book = snapshot.data!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // 1. Compact Book Identity Hero (Side-by-side)
        _buildBookIdentityCard(book),

        const SizedBox(height: 16),

        // 2. Expandable Description Card
        _buildDescriptionCard(book),
      ],
    );
  }

  Widget _buildBookIdentityCard(Book book) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDD8E5), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17263D),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover (Aspect ratio ~2/3)
              Container(
                width: 96,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCDD8E5), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.menu_book,
                              size: 40,
                              color: Color(0xFF566B87),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.menu_book,
                          size: 40,
                          color: Color(0xFF566B87),
                        ),
                      ),
              ),

              const SizedBox(width: 16),

              // Title and Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17263D),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tác giả: ${book.authorName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A488E),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8E4F1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 13,
                            color: Color(0xFF00316E),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              book.categoryName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00316E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ISBN Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFCDD8E5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'ISBN: ${book.isbn}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF566B87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Integrated Availability Badge Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F9)),

          const SizedBox(height: 10),

          // Availability Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: book.canBorrow
                      ? const Color(0xFFE0F4EA)
                      : const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: book.canBorrow
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      book.canBorrow
                          ? Icons.check_circle
                          : Icons.error_outline,
                      size: 14,
                      color: book.canBorrow
                          ? const Color(0xFF228B53)
                          : const Color(0xFFBA1A1A),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      book.canBorrow
                          ? 'Còn ${book.copiesAvailable} / ${book.copiesTotal} cuốn'
                          : 'Hiện không thể mượn (đã hết bản khả dụng)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: book.canBorrow
                            ? const Color(0xFF196B3E)
                            : const Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Book book) {
    final hasDescription = book.description.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDD8E5), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17263D),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.article_outlined,
                size: 18,
                color: Color(0xFF1A488E),
              ),
              SizedBox(width: 6),
              Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17263D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F9)),
          const SizedBox(height: 12),

          if (!hasDescription)
            const Text(
              'Chưa có mô tả',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF566B87),
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Text(
              book.description,
              maxLines: _isDescriptionExpanded ? null : 3,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF434751),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              key: const ValueKey('toggle_description_button'),
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A488E),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _isDescriptionExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: const Color(0xFF1A488E),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStickyActionBar(Book book, bool isReserving) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFCDD8E5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F17263D),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Reserve Action Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const ValueKey('reserve_book_button'),
                    onPressed: isReserving ? null : () => _onReserveBook(book),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF1A488E),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: const Color(0xFF1A488E),
                    ),
                    icon: isReserving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A488E),
                            ),
                          )
                        : const Icon(Icons.bookmark_add_outlined, size: 20),
                    label: Text(
                      isReserving ? 'Đang xử lý...' : 'Đặt trước',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Borrow Action Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
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

                            if (!mounted) return;

                            if (borrowed == true) {
                              Navigator.of(context).pop(true);
                            } else {
                              _retry();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00316E),
                      disabledBackgroundColor: const Color(0xFFCDD8E5),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF737782),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.local_library_outlined, size: 20),
                    label: const Text(
                      'Mượn sách',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
