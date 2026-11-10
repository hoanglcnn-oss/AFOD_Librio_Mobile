import 'package:equatable/equatable.dart';

import '../data/models/create_borrowing_slip_request.dart';

abstract class BorrowingSlipEvent extends Equatable {
  const BorrowingSlipEvent();

  @override
  List<Object?> get props => [];
}

class CreateSlipRequested extends BorrowingSlipEvent {
  final CreateBorrowingSlipRequest request;

  const CreateSlipRequested(this.request);

  @override
  List<Object?> get props => [
    request.memberId,
    request.expectedReturnDays,
    request.notes,
    ...request.items.expand((item) => [item.bookId, item.quantity]),
  ];
}
