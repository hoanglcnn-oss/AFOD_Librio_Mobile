import 'models/paginated_reservations.dart';
import 'models/reservation.dart';

abstract class ReservationsRepository {
  Future<Reservation> createReservation({
    required String memberId,
    required String bookId,
    String? notes,
  });

  Future<PaginatedReservations> getReservations({
    required String memberId,
    int page = 1,
    int limit = 10,
  });

  Future<Reservation> getReservationById({
    required String reservationId,
  });

  Future<Reservation> cancelReservation({
    required String reservationId,
    String? reason,
  });
}
