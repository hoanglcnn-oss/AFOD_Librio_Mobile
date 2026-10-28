import 'package:equatable/equatable.dart';

import '../data/models/borrowing.dart';

abstract class BorrowingState extends Equatable {
  const BorrowingState();

  @override
  List<Object?> get props => [];
}

class BorrowingInitial extends BorrowingState {
  const BorrowingInitial();
}

class BorrowingSubmitting extends BorrowingState {
  const BorrowingSubmitting();
}

class BorrowingSuccess extends BorrowingState {
  final Borrowing borrowing;

  const BorrowingSuccess(this.borrowing);

  @override
  List<Object?> get props => [borrowing];
}

class BorrowingFailure extends BorrowingState {
  final String message;

  const BorrowingFailure(this.message);

  @override
  List<Object?> get props => [message];
}
