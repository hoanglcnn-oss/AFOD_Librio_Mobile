import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/books_bloc.dart';
import '../bloc/books_event.dart';
import '../bloc/books_state.dart';
import '../data/books_repository.dart';
import 'books_detail_screen.dart';
import 'widgets/book_card.dart';

class BooksScreen extends StatefulWidget {
  final BooksRepository repository;

  const BooksScreen({super.key, required this.repository});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 1. Xử lý tìm kiếm
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

  // 2. Giao diện chính
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thanh tìm kiếm
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSearch(),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên sách, tác giả...',

              // Nút xác nhận tìm kiếm
              prefixIcon: IconButton(
                tooltip: 'Tìm kiếm',
                icon: const Icon(Icons.search),
                onPressed: _submitSearch,
              ),

              // Nút xóa tìm kiếm
              suffixIcon: IconButton(
                tooltip: 'Xóa tìm kiếm',
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              ),

              border: const OutlineInputBorder(),
            ),
          ),
        ),

        // Danh sách sách
        Expanded(
          child: BlocBuilder<BooksBloc, BooksState>(
            builder: (context, state) {
              return _buildBooksContent(context, state);
            },
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
      final books = state.booksPage.books;

      // Empty
      if (books.isEmpty) {
        return const Center(child: Text('Không tìm thấy sách phù hợp'));
      }

      // List
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];

          return BookCard(
            book: book,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookDetailScreen(
                    bookId: book.id,
                    repository: widget.repository,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
