import 'package:equatable/equatable.dart';

import '../data/models/create_borrowing_request.dart';

abstract class BorrowingEvent extends Equatable {
  const BorrowingEvent();

  @override
  List<Object?> get props => [];
}

class BorrowBookRequested extends BorrowingEvent {
  final CreateBorrowingRequest request;

  const BorrowBookRequested(this.request);

  @override
  List<Object?> get props => [
    request.memberId,
    request.bookId,
    request.durationDays,
    request.notes,
  ];
}
