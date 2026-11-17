import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/return_slip_bloc.dart';
import '../../bloc/return_slip_event.dart';
import '../../bloc/return_slip_state.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../../data/models/return_slip_items_request.dart';

class BorrowingSlipReturnScreen extends StatelessWidget {
  final BorrowingSlip slip;
  final BorrowingSlipsRepository repository;

  const BorrowingSlipReturnScreen({
    super.key,
    required this.slip,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReturnSlipBloc(repository: repository),
      child: _ReturnContent(slip: slip),
    );
  }
}

class _ReturnContent extends StatefulWidget {
  final BorrowingSlip slip;

  const _ReturnContent({required this.slip});

  @override
  State<_ReturnContent> createState() => _ReturnContentState();
}

class _ReturnContentState extends State<_ReturnContent> {
  final Map<String, int> _quantities = {};

  void _toggle(BorrowingSlipItem item, bool selected) {
    setState(() {
      if (selected) {
        _quantities[item.id] = 1;
      } else {
        _quantities.remove(item.id);
      }
    });
  }

  void _changeQuantity(String itemId, int quantity) {
    setState(() {
      _quantities[itemId] = quantity;
    });
  }

  void _submit() {
    if (_quantities.isEmpty) return;

    final request = ReturnSlipItemsRequest(
      items: [
        for (final entry in _quantities.entries)
          ReturnSlipItemRequest(
            itemId: entry.key,
            quantity: entry.value,
            returnCondition: 'GOOD',
          ),
      ],
      isPaidNow: false,
    );

    context.read<ReturnSlipBloc>().add(
      ReturnSlipRequested(slipId: widget.slip.id, request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.slip.items
        .where((item) => item.remainingQuantity > 0)
        .toList();

    return BlocConsumer<ReturnSlipBloc, ReturnSlipState>(
      listener: (context, state) {
        if (state is ReturnSlipSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final submitting = state is ReturnSlipSubmitting;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Chọn sách trả',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.slip.slipNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chọn những cuốn thực tế muốn trả trong đợt này.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chỉ xử lý sách còn đang mượn. '
                'Tình trạng trả: GOOD. '
                'Tiền phạt chưa được đánh dấu là đã thanh toán.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),

              for (final item in available)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          activeColor: const Color(0xFF0D9488),
                          value: _quantities.containsKey(item.id),
                          onChanged: submitting
                              ? null
                              : (value) => _toggle(item, value ?? false),
                          title: Text(
                            item.bookTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            'Chưa trả: ${item.remainingQuantity} cuốn',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                        if (_quantities.containsKey(item.id))
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Số lượng trả:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const Spacer(),
                                DropdownButton<int>(
                                  value: _quantities[item.id],
                                  onChanged: submitting
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            _changeQuantity(item.id, value);
                                          }
                                        },
                                  items: [
                                    for (
                                      int quantity = 1;
                                      quantity <= item.remainingQuantity;
                                      quantity++
                                    )
                                      DropdownMenuItem(
                                        value: quantity,
                                        child: Text('$quantity'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              if (state is ReturnSlipFailure) ...[
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(color: Color(0xFFDC2626)),
                ),
              ],

              const SizedBox(height: 24),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: submitting || _quantities.isEmpty ? null : _submit,
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Xác nhận trả '
                        '${_quantities.values.fold<int>(0, (a, b) => a + b)}'
                        ' cuốn',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
