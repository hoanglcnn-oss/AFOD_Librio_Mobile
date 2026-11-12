import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/return_slip_bloc.dart';
import '../../bloc/return_slip_event.dart';
import '../../bloc/return_slip_state.dart';
import '../../data/borrowing_slips_repository.dart';
import '../../data/models/borrowing_slip.dart';
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
          appBar: AppBar(title: const Text('Chọn sách trả')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.slip.slipNumber,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Chọn những cuốn thực tế muốn trả trong đợt này.'),
              const SizedBox(height: 8),
              const Text(
                'Chỉ xử lý sách còn đang mượn. '
                'Tình trạng trả: GOOD. '
                'Tiền phạt chưa được đánh dấu là đã thanh toán.',
              ),
              const SizedBox(height: 16),

              for (final item in available)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: _quantities.containsKey(item.id),
                          onChanged: submitting
                              ? null
                              : (value) => _toggle(item, value ?? false),
                          title: Text(item.bookTitle),
                          subtitle: Text(
                            'Chưa trả: ${item.remainingQuantity} cuốn',
                          ),
                        ),
                        if (_quantities.containsKey(item.id))
                          Row(
                            children: [
                              const Text('Số lượng trả:'),
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
                      ],
                    ),
                  ),
                ),

              if (state is ReturnSlipFailure) ...[
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],

              const SizedBox(height: 24),

              FilledButton(
                onPressed: submitting || _quantities.isEmpty ? null : _submit,
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Xác nhận trả '
                        '${_quantities.values.fold<int>(0, (a, b) => a + b)}'
                        ' cuốn',
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

