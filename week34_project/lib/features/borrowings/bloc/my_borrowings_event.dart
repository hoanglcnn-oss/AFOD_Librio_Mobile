import 'package:equatable/equatable.dart';

abstract class MyBorrowingsEvent extends Equatable {
  const MyBorrowingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyBorrowings extends MyBorrowingsEvent {
  final String memberId;

  const LoadMyBorrowings(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

class ReturnBookRequested extends MyBorrowingsEvent {
  final String borrowingId;

  const ReturnBookRequested(this.borrowingId);

  @override
  List<Object?> get props => [borrowingId];
}

class RenewBorrowingRequested extends MyBorrowingsEvent {
  final String borrowingId;
  final int extraDays;

  const RenewBorrowingRequested({
    required this.borrowingId,
    this.extraDays = 7,
  });

  @override
  List<Object?> get props => [borrowingId, extraDays];
}
