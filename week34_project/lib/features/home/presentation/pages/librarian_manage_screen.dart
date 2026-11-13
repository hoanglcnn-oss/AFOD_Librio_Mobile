import 'package:flutter/material.dart';

import '../../../borrowing_slips/data/api_borrowing_slips_repository.dart';
import '../../../borrowing_slips/data/borrowing_slips_repository.dart';
import '../../../borrowing_slips/presentation/pages/manage_borrowing_slips_screen.dart';

class LibrarianManageScreen extends StatelessWidget {
  final BorrowingSlipsRepository borrowingSlipsRepository;

  LibrarianManageScreen({
    super.key,
    BorrowingSlipsRepository? borrowingSlipsRepository,
  }) : borrowingSlipsRepository =
            borrowingSlipsRepository ?? ApiBorrowingSlipsRepository();

  @override
  Widget build(BuildContext context) {
    return ManageBorrowingSlipsScreen(
      repository: borrowingSlipsRepository,
    );
  }
}
