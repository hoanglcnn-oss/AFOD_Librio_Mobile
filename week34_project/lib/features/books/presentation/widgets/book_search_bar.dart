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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F17263D),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search icon on the left
            IconButton(
              tooltip: 'Tìm kiếm',
              splashRadius: 20,
              icon: const Icon(
                Icons.search,
                size: 22,
                color: Color(0xFF566B87),
              ),
              onPressed: onSearch,
            ),
            // Full-width search input
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF17263D)),
                decoration: const InputDecoration(
                  hintText: 'Tìm theo tên sách, tác giả...',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF566B87)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            // Clear search action
            IconButton(
              tooltip: 'Xóa tìm kiếm',
              splashRadius: 20,
              icon: const Icon(Icons.clear, size: 20, color: Color(0xFF566B87)),
              onPressed: onClear,
            ),
            // Vertical divider separating clear action from ISBN scanner action
            Container(
              height: 20,
              width: 1,
              color: const Color(0xFFE2E8F0),
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
            // ISBN scanner icon at the far right
            IconButton(
              tooltip: 'Quét mã ISBN',
              splashRadius: 20,
              icon: const Icon(
                Icons.qr_code_scanner,
                size: 20,
                color: Color(0xFF1A488E),
              ),
              onPressed: onScanBarcode,
            ),
          ],
        ),
      ),
    );
  }
}
