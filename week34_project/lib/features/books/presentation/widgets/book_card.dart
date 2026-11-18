import 'package:flutter/material.dart';

import '../../data/models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool selectionMode;
  final bool isSelected;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.selectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBorrowDisabled = selectionMode && !book.canBorrow;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: selectionMode && isSelected
          ? const Color(0xFFF0FDFA)
          : const Color(0xFFF7FAFD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selectionMode && isSelected
              ? const Color(0xFF0D9488)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isBorrowDisabled ? null : onTap,
        child: Opacity(
          opacity: isBorrowDisabled ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.menu_book,
                            size: 36,
                            color: Color(0xFF94A3B8),
                          ),
                        )
                      : const Icon(
                          Icons.menu_book,
                          size: 36,
                          color: Color(0xFF94A3B8),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ) ??
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.canBorrow
                            ? 'Còn ${book.copiesAvailable} cuốn'
                            : 'Không thể mượn',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: book.canBorrow
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectionMode)
                  if (book.canBorrow)
                    Transform.scale(
                      scale: 1.25,
                      child: Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF0D9488),
                        onChanged: (_) => onTap?.call(),
                      ),
                    )
                  else
                    Container(
                      key: const Key('book_card_unavailable_minus'),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF94A3B8),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
