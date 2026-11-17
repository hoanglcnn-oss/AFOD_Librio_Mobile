import 'package:flutter/material.dart';

class BorrowDurationPicker extends StatelessWidget {
  final int days;
  final TextEditingController daysController;
  final bool isDaysValid;
  final bool submitting;
  final bool isEmbedded;
  final void Function(int days)? onDaysChanged;

  const BorrowDurationPicker({
    super.key,
    required this.days,
    required this.daysController,
    required this.isDaysValid,
    required this.submitting,
    this.isEmbedded = false,
    this.onDaysChanged,
  });

  DateTime get _expectedReturnDate {
    final now = DateTime.now();
    return now.add(Duration(days: days > 0 ? days : 0));
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _pickDate(BuildContext context) async {
    if (submitting) return;
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 30));
    final initialDate = (days >= 1 && days <= 30)
        ? now.add(Duration(days: days))
        : now.add(const Duration(days: 14));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate)
          ? lastDate
          : (initialDate.isBefore(firstDate) ? firstDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Chọn ngày hẹn trả sách',
      confirmText: 'Chọn',
      cancelText: 'Hủy',
    );

    if (picked != null) {
      final todayStart = DateTime(now.year, now.month, now.day);
      final pickedStart = DateTime(picked.year, picked.month, picked.day);
      final calculatedDays = pickedStart.difference(todayStart).inDays;
      if (calculatedDays >= 1 && calculatedDays <= 30) {
        daysController.text = '$calculatedDays';
        onDaysChanged?.call(calculatedDays);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);
    const borderHairline = Color(0xFFE2E8F0);
    const tealAccent = Color(0xFF0D9488);
    const tealBg = Color(0xFFF0FDFA);
    const errorRed = Color(0xFFDC2626);
    const errorBg = Color(0xFFFEF2F2);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: primaryNavy,
            ),
            const SizedBox(width: 8),
            const Text(
              'Thời hạn mượn',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: primaryNavy,
              ),
            ),
            const Spacer(),
            const Text(
              'Tối đa 30 ngày',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dải chip template nhanh theo DESIGN.md
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 3, 7, 14, 30].map((d) {
            final isSelected = days == d;
            return ChoiceChip(
              label: Text('$d ngày'),
              selected: isSelected,
              selectedColor: primaryNavy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? primaryNavy : borderHairline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
        const SizedBox(height: 14),

        // Hàng kết hợp: [Số ngày mượn] (bên trái) + [Dự kiến trả sách] (bên phải)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bên trái (tỉ lệ 4): Ô nhập số ngày cụ thể
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: daysController,
                enabled: !submitting,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: primaryNavy,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Số ngày mượn',
                  hintText: '1 - 30',
                  suffixText: 'ngày',
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderHairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: borderHairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: tealAccent, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: errorRed, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: errorRed, width: 2),
                  ),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  onDaysChanged?.call(parsed ?? 0);
                },
              ),
            ),
            const SizedBox(width: 10),

            // Bên phải (tỉ lệ 6): Thẻ hiển thị ngày trả dự kiến + bấm vào mở DatePicker trực tiếp
            Expanded(
              flex: 6,
              child: InkWell(
                onTap: submitting ? null : () => _pickDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDaysValid ? tealBg : errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDaysValid
                          ? const Color(0xFFCCFBF1)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 20,
                        color: isDaysValid ? tealAccent : errorRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDaysValid
                                  ? 'Dự kiến trả sách: (+$days ngày)'
                                  : 'Dự kiến trả sách:',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDaysValid ? textMuted : errorRed,
                              ),
                            ),
                            Text(
                              isDaysValid
                                  ? _formatDate(_expectedReturnDate)
                                  : 'Số ngày không hợp lệ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDaysValid ? primaryNavy : errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit_calendar_outlined,
                        size: 18,
                        color: isDaysValid ? tealAccent : errorRed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Thông báo lỗi trải hết cả dòng khi số ngày mượn không hợp lệ
        if (!isDaysValid) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: errorRed),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Thời hạn mượn phải từ 1 đến 30 ngày',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (isEmbedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderHairline),
      ),
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }
}
