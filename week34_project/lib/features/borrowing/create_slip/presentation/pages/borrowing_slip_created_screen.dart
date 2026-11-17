import 'package:flutter/material.dart';

import '../../../shared/models/borrowing_slip.dart';
import '../../../shared/repositories/borrowing_slips_repository.dart';
import '../../../slip_management/presentation/pages/borrowing_slip_detail_screen.dart';
import '../../../slip_management/presentation/pages/borrowing_slip_list_screen.dart';
import '../../../../members/data/repositories/members_repository.dart';
import '../widgets/borrow_slip_success_dialog.dart';

class BorrowingSlipCreatedScreen extends StatefulWidget {
  final BorrowingSlip slip;
  final BorrowingSlipsRepository repository;
  final MembersRepository membersRepository;

  const BorrowingSlipCreatedScreen({
    super.key,
    required this.slip,
    required this.repository,
    required this.membersRepository,
  });

  @override
  State<BorrowingSlipCreatedScreen> createState() =>
      _BorrowingSlipCreatedScreenState();
}

class _BorrowingSlipCreatedScreenState
    extends State<BorrowingSlipCreatedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccess());
  }

  Future<void> _showSuccess() async {
    if (!mounted) return;
    final openDetail = await showBorrowSlipSuccessDialog(
      context,
      slipNumber: widget.slip.slipNumber,
    );
    if (!mounted || openDetail != true) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BorrowingSlipDetailScreen(
          slipId: widget.slip.id,
          repository: widget.repository,
          membersRepository: widget.membersRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Phiếu mượn của tôi'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop(true)),
      ),
      body: BorrowingSlipsScreen(
        repository: widget.repository,
        memberId: widget.slip.memberId,
        initialStatus: 'PENDING_APPROVAL',
      ),
    );
  }
}
