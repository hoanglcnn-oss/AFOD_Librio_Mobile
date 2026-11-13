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

  bool _selectionMode = false;

  // Lưu đối tượng Book để không mất lựa chọn khi tìm kiếm/phân trang.
  final Map<String, Book> _selectedBooks = {};

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
    _searchController.dispose();
    super.dispose();
  }

  // Giao diện chính
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectionMode
                      ? 'Đã chọn ${_selectedBooks.length} đầu sách'
                      : 'Danh sách sách',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _toggleSelectionMode,
                icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
                label: Text(_selectionMode ? 'Hủy' : 'Chọn nhiều'),
              ),
            ],
          ),
        ),

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
                  onPressed: _selectedBooks.isEmpty ? null : _confirmSelection,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Tiếp tục (${_selectedBooks.length} sách)'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 3. Hiển thị dữ liệu theo trạng thái BooksBloc
  Widget _buildBooksContent(BuildContext context, BooksState state) {
    // Loading
    if (state is BooksInitial || state is BooksLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (state is BooksFailure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.message),
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
        return const Center(child: Text('Không tìm thấy sách phù hợp'));
      }

      // Danh sách sách: xem chi tiết hoặc chọn nhiều
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
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
}
