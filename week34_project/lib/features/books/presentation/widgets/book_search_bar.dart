import 'package:flutter/material.dart';

class BookSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback onScanBarcode;

  const BookSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
    required this.onScanBarcode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên sách, tác giả...',
          // Nút tìm kiếm bên trái
          prefixIcon: IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search),
            onPressed: onSearch,
          ),
          // Hai nút bên phải
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút xóa tìm kiếm
              IconButton(
                tooltip: 'Xóa tìm kiếm',
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              ),
              // Nút quét ISBN
              IconButton(
                tooltip: 'Quét mã ISBN',
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: onScanBarcode,
              ),
            ],
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
