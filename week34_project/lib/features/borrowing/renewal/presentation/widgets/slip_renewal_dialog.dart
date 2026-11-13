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
      title: const Text('Gia hạn phiếu mượn'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gia hạn toàn bộ sách trong phiếu mượn này.'),
            const SizedBox(height: 16),
            const Text(
              'Thời hạn gia hạn:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  key: const ValueKey('renew_chip_3'),
                  label: const Text('3 ngày'),
                  selected: !_isCustom && _selectedDays == 3,
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
                  label: const Text('7 ngày (mặc định)'),
                  selected: !_isCustom && _selectedDays == 7,
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
                  label: const Text('14 ngày (tối đa)'),
                  selected: !_isCustom && _selectedDays == 14,
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
                  label: const Text('Số ngày khác'),
                  selected: _isCustom,
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
                decoration: InputDecoration(
                  labelText: 'Nhập số ngày (1–14)',
                  hintText: 'Ví dụ: 5',
                  border: const OutlineInputBorder(),
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hạn trả hiện tại:'),
                      Text(
                        currentDueDateStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hạn trả sau gia hạn:'),
                      Text(
                        projectedDueDateStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isValid
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
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
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('confirm_renew_button'),
          onPressed: isValid
              ? () => Navigator.of(context).pop(effectiveDays)
              : null,
          child: const Text('Xác nhận gia hạn'),
        ),
      ],
    );
  }
}
