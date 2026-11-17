import 'package:flutter/material.dart';

import '../../../../books/data/models/book.dart';
import '../../../shared/widgets/ticket_notch_divider.dart';
import 'borrow_duration_picker.dart';
import 'borrow_selected_book_card.dart';

class BorrowSlipFormCard extends StatelessWidget {
  final List<Book> books;
  final Map<String, int> quantities;
  final Set<String> excludedBookIds;
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
  final void Function(String bookId)? onToggleExclude;
  final void Function(int days)? onDaysChanged;

  const BorrowSlipFormCard({
    super.key,
    required this.books,
    required this.quantities,
    required this.excludedBookIds,
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
    this.onToggleExclude,
    this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF0F172A);
    const borderHairline = Color(0xFFE2E8F0);
    const canvasBg = Color(0xFFF8FAFC);
    const cardBorderWidth = 1.0;

    final activeBooksCount = books
        .where((b) => !excludedBookIds.contains(b.id))
        .length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ========================================================
            // KHUNG THẺ VÉ MƯỢN DỰ THẢO (DRAFT TICKET PASS)
            // ========================================================
            Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ========================================================
                  // 1. NỬA TRÊN CỦA VÉ: DANH SÁCH SÁCH ĐÃ CHỌN
                  // ========================================================
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: borderHairline,
                          width: cardBorderWidth,
                        ),
                        left: BorderSide(
                          color: borderHairline,
                          width: cardBorderWidth,
                        ),
                        right: BorderSide(
                          color: borderHairline,
                          width: cardBorderWidth,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề phần Sách đã chọn
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_stories_outlined,
                              size: 18,
                              color: primaryNavy,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Sách đã chọn',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryNavy,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderHairline),
                              ),
                              child: Text(
                                '$activeBooksCount/${books.length} cuốn',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Danh sách từng cuốn sách được chọn
                        for (int i = 0; i < books.length; i++)
                          BorrowSelectedBookCard(
                            book: books[i],
                            quantity: quantities[books[i].id] ?? 1,
                            maxBorrowLimit: maxBorrowLimit,
                            isExcluded: excludedBookIds.contains(books[i].id),
                            submitting: submitting,
                            marginBottom: i == books.length - 1 ? 6.0 : 10.0,
                            onDecreaseQuantity: () =>
                                onDecreaseQuantity?.call(books[i].id),
                            onIncreaseQuantity: () =>
                                onIncreaseQuantity?.call(books[i].id),
                            onToggleExclude: () =>
                                onToggleExclude?.call(books[i].id),
                          ),
                      ],
                    ),
                  ),

                  // ========================================================
                  // 2. RÃNH XÉ VÉ Ở GIỮA: 2 BÁN NGUYỆT ĐỨT THỰC SỰ + NÉT ĐỨT
                  // ========================================================
                  const TicketPerforationRow(
                    backgroundColor: canvasBg,
                    ticketColor: Colors.white,
                    borderColor: borderHairline,
                    borderWidth: cardBorderWidth,
                    height: 24,
                  ),

                  // ========================================================
                  // 3. NỬA DƯỚI CỦA VÉ: THIẾT LẬP THỜI HẠN MƯỢN
                  // ========================================================
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: borderHairline,
                          width: cardBorderWidth,
                        ),
                        left: BorderSide(
                          color: borderHairline,
                          width: cardBorderWidth,
                        ),
                        right: BorderSide(
                          color: borderHairline,
                          width: cardBorderWidth,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Widget chọn thời hạn mượn (nhúng phẳng vào nửa dưới của vé)
                        BorrowDurationPicker(
                          days: days,
                          daysController: daysController,
                          isDaysValid: isDaysValid,
                          submitting: submitting,
                          isEmbedded: true,
                          onDaysChanged: onDaysChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Thẻ hạn mức độc giả (tích hợp lưu ý xét duyệt)
            debtSummaryCard,

            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
