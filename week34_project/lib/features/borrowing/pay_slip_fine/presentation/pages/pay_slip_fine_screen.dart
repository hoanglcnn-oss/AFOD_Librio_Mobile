import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/pay_slip_fine_bloc.dart';
import '../../bloc/pay_slip_fine_event.dart';
import '../../bloc/pay_slip_fine_state.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/widgets/borrowing_slip_ui_helper.dart';

class PaySlipFineScreen extends StatelessWidget {
  final BorrowingSlip slip;
  final BorrowingSlipsRepository repository;

  const PaySlipFineScreen({
    super.key,
    required this.slip,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaySlipFineBloc(repository: repository),
      child: _PaySlipFineContent(slip: slip),
    );
  }
}

class _PaySlipFineContent extends StatelessWidget {
  final BorrowingSlip slip;

  const _PaySlipFineContent({required this.slip});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaySlipFineBloc, PaySlipFineState>(
      listener: (context, state) {
        if (state is PaySlipFineSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final submitting = state is PaySlipFineSubmitting;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Ghi nhận thu tiền phạt',
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
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slip.slipNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Số tiền phạt cần xác nhận đã thu:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          BorrowingSlipUiHelper.formatMoney(slip.totalFine),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chỉ xác nhận khi đã thực sự thu đủ tiền '
                          'từ độc giả. Thao tác này không thực hiện '
                          'chuyển tiền online.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state is PaySlipFineFailure) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w500,
                      ),
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
                    onPressed: submitting
                        ? null
                        : () {
                            context.read<PaySlipFineBloc>().add(
                              PaySlipFineRequested(slip.id),
                            );
                          },
                    child: submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Xác nhận đã thu đủ tiền',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
