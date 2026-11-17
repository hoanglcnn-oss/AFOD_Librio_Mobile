import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

/// Modal dialog allowing user to choose renewal duration (preset or custom days)
/// and returns the selected duration in days, or null if cancelled.
class SlipRenewalDialog extends StatefulWidget {
  final BorrowingSlip slip;

  const SlipRenewalDialog({
    super.key,
    required this.slip,
  });

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
    _customController = TextEditingController();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  bool _isDurationValid() {
    if (!_isCustom) {
      return _selectedDays >= 1 && _selectedDays <= 14;
    }
    final parsed = int.tryParse(_customController.text.trim());
    return parsed != null && parsed >= 1 && parsed <= 14;
  }

  int _getEffectiveDays() {
    if (!_isCustom) {
      return _selectedDays;
    }
    final parsed = int.tryParse(_customController.text.trim());
    if (parsed != null && parsed >= 1 && parsed <= 14) {
      return parsed;
    }
    return _selectedDays;
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _isDurationValid();
    final effectiveDays = _getEffectiveDays();

    final currentDueDateStr =
        BorrowingSlipUiHelper.formatDate(widget.slip.dueDate);
    final projectedDueDateStr = isValid
        ? BorrowingSlipUiHelper.formatDate(
            widget.slip.dueDate.add(Duration(days: effectiveDays)),
          )
        : '---';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      title: const Text(
        'Gia hạn phiếu mượn',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gia hạn toàn bộ sách trong phiếu mượn này.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thời hạn gia hạn:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  key: const ValueKey('renew_chip_3'),
                  label: Text(
                    '3 ngày',
                    style: TextStyle(
                      color: (!_isCustom && _selectedDays == 3)
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontWeight: (!_isCustom && _selectedDays == 3)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: !_isCustom && _selectedDays == 3,
                  selectedColor: const Color(0xFF0F172A),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: (!_isCustom && _selectedDays == 3)
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustom = false;
                        _selectedDays = 3;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  key: const ValueKey('renew_chip_7'),
                  label: Text(
                    '7 ngày (mặc định)',
                    style: TextStyle(
                      color: (!_isCustom && _selectedDays == 7)
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontWeight: (!_isCustom && _selectedDays == 7)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: !_isCustom && _selectedDays == 7,
                  selectedColor: const Color(0xFF0F172A),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: (!_isCustom && _selectedDays == 7)
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustom = false;
                        _selectedDays = 7;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  key: const ValueKey('renew_chip_14'),
                  label: Text(
                    '14 ngày (tối đa)',
                    style: TextStyle(
                      color: (!_isCustom && _selectedDays == 14)
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontWeight: (!_isCustom && _selectedDays == 14)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: !_isCustom && _selectedDays == 14,
                  selectedColor: const Color(0xFF0F172A),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: (!_isCustom && _selectedDays == 14)
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustom = false;
                        _selectedDays = 14;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  key: const ValueKey('renew_chip_custom'),
                  label: Text(
                    'Số ngày khác',
                    style: TextStyle(
                      color: _isCustom ? Colors.white : const Color(0xFF334155),
                      fontWeight: _isCustom ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: _isCustom,
                  selectedColor: const Color(0xFF0F172A),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: _isCustom
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustom = true;
                      });
                    }
                  },
                ),
              ],
            ),
            if (_isCustom) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('renew_custom_input'),
                controller: _customController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Nhập số ngày (1–14)',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  hintText: 'Ví dụ: 5',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                  ),
                  errorText: _customController.text.isNotEmpty && !isValid
                      ? 'Số ngày phải từ 1 đến 14'
                      : null,
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hạn trả hiện tại:',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      Text(
                        currentDueDateStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hạn trả sau gia hạn:',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      Text(
                        projectedDueDateStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isValid
                              ? const Color(0xFF0D9488)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Điều kiện gia hạn sẽ được hệ thống kiểm tra tự động.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
          ),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('confirm_renew_button'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isValid
              ? () => Navigator.of(context).pop(effectiveDays)
              : null,
          child: const Text('Xác nhận gia hạn'),
        ),
      ],
    );
  }
}
