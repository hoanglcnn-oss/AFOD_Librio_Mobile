import 'package:flutter/material.dart';

import 'package:week34_project/features/books/data/models/book.dart';

class BorrowSelectedBookCard extends StatelessWidget {
  final Book book;
  final int quantity;
  final int? maxBorrowLimit;
  final bool isExcluded;
  final bool submitting;
  final double marginBottom;
  final VoidCallback? onIncreaseQuantity;
  final VoidCallback? onDecreaseQuantity;
  final VoidCallback? onToggleExclude;

  const BorrowSelectedBookCard({
    super.key,
    required this.book,
    required this.quantity,
    this.maxBorrowLimit,
    this.isExcluded = false,
    this.submitting = false,
    this.marginBottom = 12.0,
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
    this.onToggleExclude,
  });

  Widget _buildCoverPlaceholder(Color textMuted) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: textMuted,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);
    const borderHairline = Color(0xFFE2E8F0);
    const greenSuccess = Color(0xFF16A34A);
    const greenBg = Color(0xFFF0FDF4);
    const greenBorder = Color(0xFFBBF7D0);
    const tealAccent = Color(0xFF0D9488);
    const errorRed = Color(0xFFDC2626);

    final canDecrease = !submitting && !isExcluded && quantity > 1;
    final canIncrease = !submitting &&
        !isExcluded &&
        quantity < book.copiesAvailable &&
        (maxBorrowLimit == null ||
            maxBorrowLimit! <= 0 ||
            quantity < maxBorrowLimit!);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isExcluded ? 0.45 : 1.0,
      child: Container(
        margin: EdgeInsets.only(bottom: marginBottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExcluded
                ? borderHairline.withValues(alpha: 0.6)
                : borderHairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bìa sách kéo từ đầu đến cuối mép trái (rộng 82px)
              SizedBox(
                width: 82,
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildCoverPlaceholder(textMuted),
                      )
                    : _buildCoverPlaceholder(textMuted),
              ),

              // Nội dung bên phải
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hàng trên: Tiêu đề + tác giả + Nút thùng rác / Undo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryNavy,
                                    height: 1.25,
                                    decoration: isExcluded
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                if (book.authorName.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    book.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (onToggleExclude != null)
                            IconButton(
                              icon: Icon(
                                isExcluded
                                    ? Icons.undo_rounded
                                    : Icons.delete_outline,
                                color: isExcluded
                                    ? tealAccent
                                    : errorRed.withValues(alpha: 0.8),
                                size: 26,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              tooltip: isExcluded
                                  ? 'Khôi phục sách'
                                  : 'Bỏ khỏi phiếu mượn',
                              onPressed: submitting ? null : onToggleExclude,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Hàng dưới: Trạng thái loại trừ HOẶC [Còn X cuốn] + [- 1 +]
                      if (isExcluded)
                        Row(
                          children: [
                            const Icon(
                              Icons.visibility_off_outlined,
                              size: 16,
                              color: textMuted,
                            ),
                            const SizedBox(width: 5),
                            const Expanded(
                              child: Text(
                                'Đã loại trừ khỏi phiếu mượn',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: submitting ? null : onToggleExclude,
                              icon: const Icon(
                                Icons.undo_rounded,
                                size: 15,
                                color: tealAccent,
                              ),
                              label: const Text(
                                'Khôi phục',
                                style: TextStyle(
                                  color: tealAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Badge Còn X cuốn
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: greenBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: greenBorder),
                              ),
                              child: Text(
                                'Còn ${book.copiesAvailable} cuốn',
                                style: const TextStyle(
                                  color: greenSuccess,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Capsule stepper [- 1 +]
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 22,
                                    padding: const EdgeInsets.all(5),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    onPressed:
                                        canDecrease ? onDecreaseQuantity : null,
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    tooltip: 'Giảm 1',
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: primaryNavy,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 22,
                                    padding: const EdgeInsets.all(5),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    onPressed:
                                        canIncrease ? onIncreaseQuantity : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                    tooltip: 'Tăng 1',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
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
