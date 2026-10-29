import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/books_repository.dart';
import 'books_detail_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final BooksRepository repository;

  const BarcodeScannerScreen({super.key, required this.repository});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _findBook(String rawIsbn) async {
    if (_isLoading) return;

    final isbn = rawIsbn.replaceAll(RegExp(r'[\s-]'), '');

    if (!RegExp(r'^\d{13}$').hasMatch(isbn)) {
      setState(() {
        _error = 'Vui lòng nhập ISBN-13 gồm 13 chữ số';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final book = await widget.repository.getBookByIsbn(isbn);

      if (!mounted) return;

      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              BookDetailScreen(bookId: book.id, repository: widget.repository),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.response?.statusCode == 404
            ? 'Không tìm thấy sách với ISBN này'
            : 'Không thể tra cứu sách. Vui lòng thử lại.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Đã xảy ra lỗi khi tra cứu sách';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tra cứu ISBN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner, size: 72),
            const SizedBox(height: 12),
            const Text('Quét mã vạch ISBN-13'),
            const SizedBox(height: 12),
            const Text('Camera sẽ được tích hợp ở bước tiếp theo.'),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 13,
              decoration: const InputDecoration(
                labelText: 'Nhập ISBN để thử nghiệm',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _findBook,
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isLoading ? null : () => _findBook(_controller.text),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Tìm sách'),
            ),
          ],
        ),
      ),
    );
  }
}
