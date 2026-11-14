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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: selectionMode && isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : const Color(0xFFF7FAFD),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: selectionMode && !book.canBorrow ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 100,
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.menu_book, size: 40),
                      )
                    : const Icon(Icons.menu_book, size: 40),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.canBorrow
                          ? 'Còn ${book.copiesAvailable} cuốn'
                          : 'Không thể mượn',
                      style: TextStyle(
                        color: book.canBorrow
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: book.canBorrow ? (_) => onTap?.call() : null,
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
