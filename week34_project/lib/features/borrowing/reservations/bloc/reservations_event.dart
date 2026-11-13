import 'dart:async';
import 'package:equatable/equatable.dart';

abstract class ReservationsEvent extends Equatable {
  const ReservationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReservations extends ReservationsEvent {
  final String memberId;
  final int page;
  final int limit;

  const LoadReservations({
    required this.memberId,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [memberId, page, limit];
}

class RefreshReservations extends ReservationsEvent {
  final String memberId;
  final Completer<void>? completer;

  const RefreshReservations(this.memberId, {this.completer});

  @override
  List<Object?> get props => [memberId];
}

class CancelReservationRequested extends ReservationsEvent {
  final String reservationId;
  final String memberId;
  final String? reason;

  const CancelReservationRequested({
    required this.reservationId,
    required this.memberId,
    this.reason,
  });

  @override
  List<Object?> get props => [reservationId, memberId, reason];
}

class CreateReservationRequested extends ReservationsEvent {
  final String memberId;
  final String bookId;
  final String? notes;

  const CreateReservationRequested({
    required this.memberId,
    required this.bookId,
    this.notes,
  });

  @override
  List<Object?> get props => [memberId, bookId, notes];
}
