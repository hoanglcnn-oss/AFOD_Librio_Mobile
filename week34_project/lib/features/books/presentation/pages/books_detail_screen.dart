import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/books_repository.dart';
import '../../data/models/book.dart';
import '../../../borrowings/presentation/pages/borrow_confirm_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  final BooksRepository repository;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    required this.repository,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<Book> _bookFuture;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  void _loadBook() {
    _bookFuture = widget.repository.getBookById(widget.bookId);
  }

  void _retry() {
    setState(_loadBook);
  }

  @override
  Widget build(BuildContext context) {
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
                    : 'Hiện không thể mượn',
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
                book.description.isEmpty ? 'Chưa có mô tả' : book.description,
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: !book.canBorrow
                    ? null
                    : () async {
                        final borrowed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => BorrowConfirmScreen(book: book),
                          ),
                        );

                        if (!context.mounted) return;

                        if (borrowed == true) {
                          Navigator.of(context).pop(true);
                        }
                      },
                child: const Text('Mượn sách'),
              ),
            ],
          );
        },
      ),
    );
  }
}
