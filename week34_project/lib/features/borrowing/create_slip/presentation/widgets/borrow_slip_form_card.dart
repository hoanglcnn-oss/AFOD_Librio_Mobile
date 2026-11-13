import 'package:flutter/material.dart';

import '../../../../books/data/models/book.dart';

class BorrowSlipFormCard extends StatelessWidget {
  final List<Book> books;
  final Map<String, int> quantities;
  final int days;
  final TextEditingController daysController;
  final bool isDaysValid;
  final bool submitting;
  final bool canSubmit;
  final int? maxBorrowLimit;
  final String? errorMessage;
  final Widget debtSummaryCard;
  final void Function(String bookId)? onDecreaseQuantity;
  final void Function(String bookId)? onIncreaseQuantity;
  final void Function(int days)? onDaysChanged;
  final VoidCallback? onSubmit;

  const BorrowSlipFormCard({
    super.key,
    required this.books,
    required this.quantities,
    required this.days,
    required this.daysController,
    required this.isDaysValid,
    required this.submitting,
    required this.canSubmit,
    required this.debtSummaryCard,
    this.maxBorrowLimit,
    this.errorMessage,
    this.onDecreaseQuantity,
    this.onIncreaseQuantity,
    this.onDaysChanged,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Sách đã chọn', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            for (final book in books)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Còn ${book.copiesAvailable} cuốn'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Số lượng:'),
                          const Spacer(),
                          IconButton(
                            onPressed: submitting || (quantities[book.id] ?? 1) <= 1
                                ? null
                                : () => onDecreaseQuantity?.call(book.id),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${quantities[book.id] ?? 1}'),
                          IconButton(
                            onPressed: submitting ||
                                    (quantities[book.id] ?? 1) >=
                                        book.copiesAvailable ||
                                    (maxBorrowLimit != null &&
                                        maxBorrowLimit! > 0 &&
                                        (quantities[book.id] ?? 1) >=
                                            maxBorrowLimit!)
                                ? null
                                : () => onIncreaseQuantity?.call(book.id),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Card Hạn mức mượn sách
            debtSummaryCard,

            const SizedBox(height: 20),

            Text(
              'Thời hạn mượn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: daysController,
              enabled: !submitting,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số ngày mượn',
                hintText: 'Nhập từ 1 đến 30 ngày',
                suffixText: 'ngày',
                border: const OutlineInputBorder(),
                errorText: !isDaysValid
                    ? 'Thời hạn mượn phải từ 1 đến 30 ngày'
                    : null,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                onDaysChanged?.call(parsed ?? 0);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [1, 3, 7, 14, 30].map((d) {
                return ChoiceChip(
                  label: Text('$d ngày'),
                  selected: days == d,
                  onSelected: submitting
                      ? null
                      : (selected) {
                          if (selected) {
                            daysController.text = '$d';
                            onDaysChanged?.call(d);
                          }
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            const Text(
              'Phiếu sẽ được gửi để chờ duyệt. '
              'Sách chưa được mượn ngay sau khi gửi.',
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),

            FilledButton(
              onPressed: submitting || !canSubmit ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi phiếu mượn'),
            ),
          ],
        ),
      ),
    );
  }
}
