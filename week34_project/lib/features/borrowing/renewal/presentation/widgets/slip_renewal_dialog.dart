import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

/// Modal dialog allowing user to choose renewal duration (preset or custom days)
/// and returns the selected duration in days, or null if cancelled.
class SlipRenewalDialog extends StatefulWidget {
  final BorrowingSlip slip;

  const SlipRenewalDialog({super.key, required this.slip});

  @override
  State<SlipRenewalDialog> createState() => _SlipRenewalDialogState();
}

class _SlipRenewalDialogState extends State<SlipRenewalDialog> {
  int _selectedDays = 7;
  bool _isCustom = false;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: '7');
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  bool _isDurationValid() {
    if (!_isCustom) {
      return _selectedDays >= 1 && _selectedDays <= 30;
    }
    final text = _customController.text.trim();
    if (text.isEmpty) return false;
    final parsed = int.tryParse(text);
    return parsed != null && parsed >= 1 && parsed <= 30;
  }

  int _getEffectiveDays() {
    if (!_isCustom) {
      return _selectedDays;
    }
    final parsed = int.tryParse(_customController.text.trim());
    if (parsed != null && parsed >= 1 && parsed <= 30) {
      return parsed;
    }
    return _selectedDays;
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = widget.slip.dueDate;
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 30));
    final currentDays = _getEffectiveDays();
    final initialDate = (currentDays >= 1 && currentDays <= 30)
        ? now.add(Duration(days: currentDays))
        : now.add(const Duration(days: 7));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate)
          ? lastDate
          : (initialDate.isBefore(firstDate) ? firstDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Chọn hạn trả mới sau gia hạn',
      confirmText: 'Chọn',
      cancelText: 'Hủy',
    );

    if (picked != null) {
      final baseDate = DateTime(now.year, now.month, now.day);
      final pickedDate = DateTime(picked.year, picked.month, picked.day);
      final calculatedDays = pickedDate.difference(baseDate).inDays;
      if (calculatedDays >= 1 && calculatedDays <= 30) {
        setState(() {
          _isCustom = true;
          _selectedDays = calculatedDays;
          _customController.text = '$calculatedDays';
        });
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

    final isValid = _isDurationValid();
    final effectiveDays = _getEffectiveDays();
    final isCustomEmpty = _isCustom && _customController.text.trim().isEmpty;

    final currentDueDateStr = BorrowingSlipUiHelper.formatDate(
      widget.slip.dueDate,
    );
    final projectedDueDateStr = (isValid && !isCustomEmpty)
        ? _formatDate(widget.slip.dueDate.add(Duration(days: effectiveDays)))
        : '---';

    String? customError;
    if (_isCustom && _customController.text.trim().isNotEmpty && !isValid) {
      customError = 'Số ngày phải từ 1 đến 30';
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 470),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: const Text(
        'Gia hạn phiếu mượn',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryNavy,
        ),
      ),
      content: SizedBox(
        width: 425,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Hạn trả hiện tại:',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      currentDueDateStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Header mục thời hạn mượn/gia hạn đồng nhất với BorrowDurationPicker
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: primaryNavy,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Thời hạn gia hạn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tối đa 30 ngày',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dải Choice Chips template nhanh đồng nhất với BorrowDurationPicker
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [1, 3, 7, 14, 30].map((d) {
                    final isSelected = !_isCustom && _selectedDays == d;
                    return ChoiceChip(
                      key: ValueKey('renew_chip_$d'),
                      label: Text('$d ngày'),
                      selected: isSelected,
                      selectedColor: primaryNavy,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected ? primaryNavy : borderHairline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _isCustom = false;
                            _selectedDays = d;
                            _customController.text = '$d';
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Hàng kết hợp: [Số ngày mượn/gia hạn] (bên trái flex 4) + [Dự kiến trả sách] (bên phải flex 6)
              // Đồng nhất 100% với BorrowDurationPicker
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bên trái: Ô nhập số ngày
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      key: const ValueKey('renew_custom_input'),
                      controller: _customController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
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
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: tealAccent, width: 2),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: errorRed, width: 1.5),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: errorRed, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        setState(() {
                          if (parsed != null &&
                              [1, 3, 7, 14, 30].contains(parsed)) {
                            _isCustom = false;
                            _selectedDays = parsed;
                          } else {
                            _isCustom = true;
                            _selectedDays = parsed ?? 0;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Bên phải: Thẻ hiển thị ngày trả dự kiến + bấm vào mở DatePicker trực tiếp
                  Expanded(
                    flex: 6,
                    child: InkWell(
                      onTap: () => _pickDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: (isValid && !isCustomEmpty) ? tealBg : errorBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (isValid && !isCustomEmpty)
                                ? const Color(0xFFCCFBF1)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_available_outlined,
                              size: 20,
                              color: (isValid && !isCustomEmpty)
                                  ? tealAccent
                                  : errorRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (isValid && !isCustomEmpty)
                                        ? 'Dự kiến trả sách: (+$effectiveDays ngày)'
                                        : 'Dự kiến trả sách:',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: (isValid && !isCustomEmpty)
                                          ? textMuted
                                          : errorRed,
                                    ),
                                  ),
                                  Text(
                                    projectedDueDateStr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: (isValid && !isCustomEmpty)
                                          ? primaryNavy
                                          : errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_calendar_outlined,
                              size: 18,
                              color: (isValid && !isCustomEmpty)
                                  ? tealAccent
                                  : errorRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (customError != null) ...[
                const SizedBox(height: 6),
                Text(
                  customError,
                  style: const TextStyle(color: errorRed, fontSize: 12),
                ),
              ],

              const SizedBox(height: 12),
              const Text(
                'Điều kiện gia hạn sẽ được hệ thống kiểm tra tự động.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: textMuted),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('confirm_renew_button'),
          style: FilledButton.styleFrom(
            backgroundColor: primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: (isValid && !isCustomEmpty)
              ? () => Navigator.of(context).pop(effectiveDays)
              : null,
          child: const Text('Xác nhận gia hạn'),
        ),
      ],
    );
  }
}
