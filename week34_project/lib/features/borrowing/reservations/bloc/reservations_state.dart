import 'package:equatable/equatable.dart';

import '../data/models/paginated_reservations.dart';
import '../data/models/reservation.dart';

abstract class ReservationsState extends Equatable {
  const ReservationsState();

  @override
  List<Object?> get props => [];
}

class ReservationsInitial extends ReservationsState {
  const ReservationsInitial();
}

class ReservationsLoading extends ReservationsState {
  const ReservationsLoading();
}

class ReservationsLoaded extends ReservationsState {
  final PaginatedReservations paginated;
  final String memberId;

  const ReservationsLoaded({
    required this.paginated,
    required this.memberId,
  });

  List<Reservation> get reservations => paginated.items;

  @override
  List<Object?> get props => [paginated, memberId];
}

class ReservationsFailure extends ReservationsState {
  final String message;

  const ReservationsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class ReservationCancelling extends ReservationsState {
  final PaginatedReservations paginated;
  final String memberId;
  final String reservationId;

  const ReservationCancelling({
    required this.paginated,
    required this.memberId,
    required this.reservationId,
  });

  @override
  List<Object?> get props => [paginated, memberId, reservationId];
}

class ReservationCancelSuccess extends ReservationsState {
  final PaginatedReservations paginated;
  final String memberId;
  final String message;

  const ReservationCancelSuccess({
    required this.paginated,
    required this.memberId,
    this.message = 'Hủy đặt trước thành công',
  });

  @override
  List<Object?> get props => [paginated, memberId, message];
}

class ReservationCancelFailure extends ReservationsState {
  final PaginatedReservations paginated;
  final String memberId;
  final String message;

  const ReservationCancelFailure({
    required this.paginated,
    required this.memberId,
    required this.message,
  });

  @override
  List<Object?> get props => [paginated, memberId, message];
}

class ReservationCreating extends ReservationsState {
  final String bookId;

  const ReservationCreating({required this.bookId});

  @override
  List<Object?> get props => [bookId];
}

class ReservationCreateSuccess extends ReservationsState {
  final Reservation reservation;
  final String message;

  const ReservationCreateSuccess({
    required this.reservation,
    required this.message,
  });

  @override
  List<Object?> get props => [reservation, message];
}

class ReservationCreateFailure extends ReservationsState {
  final String message;

  const ReservationCreateFailure(this.message);

  @override
  List<Object?> get props => [message];
}
