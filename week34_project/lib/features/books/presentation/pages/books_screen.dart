import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/books_bloc.dart';
import '../../bloc/books_event.dart';
import '../../bloc/books_state.dart';
import '../../data/books_repository.dart';
import '../../data/models/book.dart';
import '../widgets/book_card.dart';
import '../widgets/book_search_bar.dart';
import 'barcode_scanner_screen.dart';
import 'books_detail_screen.dart';
import '../../../borrowing/create_slip/presentation/pages/borrowing_slip_confirm_screen.dart';

class BooksScreen extends StatefulWidget {
  final BooksRepository repository;
  final VoidCallback? onBorrowSucceeded;

  const BooksScreen({
    super.key,
    required this.repository,
    this.onBorrowSucceeded,
  });

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _selectionMode = false;

  // Lưu đối tượng Book để không mất lựa chọn khi tìm kiếm/phân trang.
  final Map<String, Book> _selectedBooks = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<BooksBloc>().state;
      if (state is BooksLoaded &&
          !state.isLoadingMore &&
          state.paginationError == null &&
          state.paginatedBooks.hasNextPage) {
        context.read<BooksBloc>().add(const LoadMoreBooks());
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedBooks.clear();
    });
  }

  void _toggleBook(Book book) {
    if (!book.canBorrow) return;

    setState(() {
      if (_selectedBooks.containsKey(book.id)) {
        _selectedBooks.remove(book.id);
      } else {
        _selectedBooks[book.id] = book;
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedBooks.isEmpty) return;

    final books = _selectedBooks.values.toList();

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BorrowingSlipConfirmScreen(books: books),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      setState(() {
        _selectedBooks.clear();
        _selectionMode = false;
      });

      context.read<BooksBloc>().add(const LoadBooks());
    }
  }

  // Xử lý tìm kiếm
  void _submitSearch() {
    context.read<BooksBloc>().add(SearchBooks(_searchController.text));
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<BooksBloc>().add(const LoadBooks());
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Giao diện chính
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FAFD),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _selectionMode
                          ? 'Đã chọn ${_selectedBooks.length} đầu sách'
                          : 'Danh sách sách',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF17263D),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!_selectionMode)
                    OutlinedButton.icon(
                      onPressed: _toggleSelectionMode,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A488E),
                        side: const BorderSide(color: Color(0xFFCDD8E5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 42),
                        elevation: 1,
                        shadowColor: const Color(0x0A000000),
                      ),
                      icon: const Icon(
                        Icons.checklist,
                        size: 20,
                        color: Color(0xFF1A488E),
                      ),
                      label: const Text(
                        'Chọn nhiều',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A488E),
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _toggleSelectionMode,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF566B87),
                        side: const BorderSide(color: Color(0xFFCDD8E5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 42),
                      ),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF566B87),
                      ),
                      label: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF566B87),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Search bar
            BookSearchBar(
              controller: _searchController,
              onSearch: _submitSearch,
              onClear: _clearSearch,
              onScanBarcode: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        BarcodeScannerScreen(repository: widget.repository),
                  ),
                );
              },
            ),

            // Result count
            BlocBuilder<BooksBloc, BooksState>(
              buildWhen: (previous, current) =>
                  previous.runtimeType != current.runtimeType ||
                  (previous is BooksLoaded &&
                      current is BooksLoaded &&
                      previous.paginatedBooks.books.length !=
                          current.paginatedBooks.books.length),
              builder: (context, state) {
                if (state is BooksLoaded &&
                    state.paginatedBooks.books.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        key: const Key('books_result_count'),
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF566B87),
                          ),
                          children: [
                            const TextSpan(text: 'Hiển thị '),
                            TextSpan(
                              text: '${state.paginatedBooks.books.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF17263D),
                              ),
                            ),
                            const TextSpan(text: ' sách'),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            Expanded(
              child: BlocBuilder<BooksBloc, BooksState>(
                builder: (context, state) {
                  return _buildBooksContent(context, state);
                },
              ),
            ),

            if (_selectionMode)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selectedBooks.isEmpty
                          ? null
                          : _confirmSelection,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Tiếp tục (${_selectedBooks.length} sách)'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 3. Hiển thị dữ liệu theo trạng thái BooksBloc
  Widget _buildBooksContent(BuildContext context, BooksState state) {
    // Loading
    if (state is BooksInitial || state is BooksLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A488E)),
        ),
      );
    }

    // Error
    if (state is BooksFailure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.message,
              style: const TextStyle(color: Color(0xFF17263D)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitSearch,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Loaded
    if (state is BooksLoaded) {
      final books = state.paginatedBooks.books;

      // Empty
      if (books.isEmpty) {
        return const Center(
          child: Text(
            'Không tìm thấy sách phù hợp',
            style: TextStyle(color: Color(0xFF566B87)),
          ),
        );
      }

      // Danh sách sách: xem chi tiết hoặc chọn nhiều
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: books.length + 1,
        itemBuilder: (context, index) {
          if (index == books.length) {
            return _buildPaginationFooter(state);
          }

          final book = books[index];

          return BookCard(
            book: book,

            // Chế độ chọn nhiều
            selectionMode: _selectionMode,

            // Sách này đã được chọn chưa?
            isSelected: _selectedBooks.containsKey(book.id),

            onTap: () async {
              // Nếu đang chọn nhiều: chạm card để chọn/bỏ chọn
              if (_selectionMode) {
                _toggleBook(book);
                return;
              }

              // Bình thường: chạm card để xem chi tiết
              final borrowed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => BookDetailScreen(
                    bookId: book.id,
                    repository: widget.repository,
                  ),
                ),
              );

              if (!context.mounted) return;

              // Đồng bộ lại danh sách từ Backend sau khi xem chi tiết,
              // kể cả khi yêu cầu mượn thất bại.
              final keyword = _searchController.text.trim();

              if (keyword.isEmpty) {
                context.read<BooksBloc>().add(const LoadBooks());
              } else {
                context.read<BooksBloc>().add(SearchBooks(keyword));
              }

              // Chỉ báo có lượt mượn mới nếu API thực sự thành công.
              if (borrowed == true) {
                widget.onBorrowSucceeded?.call();
              }
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPaginationFooter(BooksLoaded state) {
    // 1. Loading
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A488E)),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Đang tải thêm...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A488E),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Error
    if (state.paginationError != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Color(0xFFBA1A1A)),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Không thể tải thêm sách.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFBA1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A488E),
                side: const BorderSide(color: Color(0xFFCDD8E5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                context.read<BooksBloc>().add(const LoadMoreBooks());
              },
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A488E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. End of list
    if (!state.paginatedBooks.hasNextPage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFCDD8E5), thickness: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Đã hiển thị tất cả sách',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF566B87),
                ),
              ),
            ),
            Expanded(child: Divider(color: Color(0xFFCDD8E5), thickness: 1)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
