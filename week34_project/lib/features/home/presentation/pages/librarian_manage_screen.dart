import 'package:flutter/material.dart';

import '../../../borrowing/shared/repositories/api_borrowing_slips_repository.dart';
import '../../../borrowing/shared/repositories/borrowing_slips_repository.dart';
import '../../../borrowing/slip_management/presentation/pages/borrowing_slip_list_screen.dart';

class LibrarianManageScreen extends StatelessWidget {
  final BorrowingSlipsRepository borrowingSlipsRepository;

  LibrarianManageScreen({
    super.key,
    BorrowingSlipsRepository? borrowingSlipsRepository,
  }) : borrowingSlipsRepository =
            borrowingSlipsRepository ?? ApiBorrowingSlipsRepository();

  @override
  Widget build(BuildContext context) {
    return BorrowingSlipsScreen(
      repository: borrowingSlipsRepository,
    );
  }
}
