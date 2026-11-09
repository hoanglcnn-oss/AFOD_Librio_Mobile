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
