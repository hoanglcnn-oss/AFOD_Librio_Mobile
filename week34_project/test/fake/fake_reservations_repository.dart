import 'dart:async';
import 'package:dio/dio.dart';
import 'package:week34_project/features/reservations/data/models/paginated_reservations.dart';
import 'package:week34_project/features/reservations/data/models/reservation.dart';
import 'package:week34_project/features/reservations/data/reservations_repository.dart';

class FakeReservationsRepository implements ReservationsRepository {
  List<Reservation> reservations = [];
  bool shouldFailGet = false;
  bool shouldFailCreate = false;
  bool shouldFailCancel = false;
  bool shouldFailGetById = false;

  DioException? getError;
  DioException? createError;
  DioException? cancelError;
  DioException? getByIdError;

  int getCallCount = 0;
  int createCallCount = 0;
  int cancelCallCount = 0;
  int getByIdCallCount = 0;

  Completer<void>? createCompleter;
  Completer<void>? cancelCompleter;
  Completer<void>? getCompleter;
  bool pauseNextGetOnly = false;

  FakeReservationsRepository({List<Reservation>? initialReservations}) {
    if (initialReservations != null) {
      reservations = List.from(initialReservations);
    }
  }

  @override
  Future<Reservation> createReservation({
    required String memberId,
    required String bookId,
    String? notes,
  }) async {
    createCallCount++;

    if (createCompleter != null) {
      await createCompleter!.future;
    }

    if (shouldFailCreate) {
      throw Exception('Create reservation failed');
    }

    if (createError != null) {
      throw createError!;
    }

    final newReservation = Reservation(
      id: 'res-${DateTime.now().millisecondsSinceEpoch}',
      reservationCode: 'RSV-${reservations.length + 1}',
      memberId: memberId,
      bookId: bookId,
      bookTitle: 'Sách #$bookId',
      status: 'PENDING',
      reservedAt: DateTime.now(),
      notes: notes,
    );

    reservations.insert(0, newReservation);
    return newReservation;
  }

  @override
  Future<PaginatedReservations> getReservations({
    required String memberId,
    int page = 1,
    int limit = 10,
  }) async {
    getCallCount++;

    if (getCompleter != null) {
      final c = getCompleter!;
      if (pauseNextGetOnly) {
        getCompleter = null;
      }
      await c.future;
    }

    if (shouldFailGet) {
      throw Exception('Get reservations failed');
    }

    if (getError != null) {
      throw getError!;
    }

    final filtered =
        reservations.where((r) => r.memberId == memberId).toList();

    final startIndex = (page - 1) * limit;
    final items = (startIndex < filtered.length)
        ? filtered.skip(startIndex).take(limit).toList()
        : <Reservation>[];

    final totalPages = (filtered.isEmpty) ? 1 : (filtered.length / limit).ceil();

    return PaginatedReservations(
      items: items,
      page: page,
      limit: limit,
      totalItems: filtered.length,
      totalPages: totalPages,
      hasNextPage: page < totalPages,
    );
  }

  @override
  Future<Reservation> getReservationById({
    required String reservationId,
  }) async {
    getByIdCallCount++;

    if (shouldFailGetById) {
      throw Exception('Get reservation by ID failed');
    }

    if (getByIdError != null) {
      throw getByIdError!;
    }

    return reservations.firstWhere(
      (r) => r.id == reservationId,
      orElse: () => throw Exception('Reservation not found: $reservationId'),
    );
  }

  @override
  Future<Reservation> cancelReservation({
    required String reservationId,
    String? reason,
  }) async {
    cancelCallCount++;

    if (cancelCompleter != null) {
      await cancelCompleter!.future;
    }

    if (shouldFailCancel) {
      throw Exception('Cancel reservation failed');
    }

    if (cancelError != null) {
      throw cancelError!;
    }

    final index = reservations.indexWhere((r) => r.id == reservationId);
    if (index == -1) {
      throw Exception('Reservation not found: $reservationId');
    }

    final updated = reservations[index].copyWith(
      status: 'CANCELLED',
      cancelledAt: DateTime.now(),
      cancellationReason: reason,
    );

    reservations[index] = updated;
    return updated;
  }
}
