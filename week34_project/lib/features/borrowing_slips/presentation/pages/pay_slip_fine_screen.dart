import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/pay_slip_fine_bloc.dart';
import '../../bloc/pay_slip_fine_event.dart';
import '../../bloc/pay_slip_fine_state.dart';
import '../../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import '../../../borrowing/shared/models/borrowing_slip.dart';
import '../widgets/borrowing_slip_ui_helper.dart';

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
          appBar: AppBar(title: const Text('Ghi nhận thu tiền phạt')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    slip.slipNumber,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text('Số tiền phạt cần xác nhận đã thu:'),
                  Text(
                    BorrowingSlipUiHelper.formatMoney(slip.totalFine),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chỉ xác nhận khi đã thực sự thu đủ tiền '
                    'từ độc giả. Thao tác này không thực hiện '
                    'chuyển tiền online.',
                  ),
                  if (state is PaySlipFineFailure) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xác nhận đã thu đủ tiền'),
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
