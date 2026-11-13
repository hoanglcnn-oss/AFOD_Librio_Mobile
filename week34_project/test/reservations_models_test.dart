import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/reservations/data/models/paginated_reservations.dart';
import 'package:week34_project/features/reservations/data/models/reservation.dart';

void main() {
  group('Reservation Model', () {
    test('Parse PENDING reservation from flat JSON', () {
      final json = {
        'id': 'res-101',
        'reservationNumber': 'RSV-001',
        'memberId': 'mem-1',
        'bookId': 'b-1',
        'bookTitle': 'Lập trình Flutter',
        'status': 'PENDING',
        'reservationDate': '2026-11-10T10:00:00Z',
        'notes': 'Lấy vào cuối tuần',
      };

      final res = Reservation.fromJson(json);

      expect(res.id, 'res-101');
      expect(res.reservationNumber, 'RSV-001');
      expect(res.memberId, 'mem-1');
      expect(res.bookId, 'b-1');
      expect(res.bookTitle, 'Lập trình Flutter');
      expect(res.status, 'PENDING');
      expect(res.isPending, isTrue);
      expect(res.isReady, isFalse);
      expect(res.isFulfilled, isFalse);
      expect(res.isCancelled, isFalse);
      expect(res.isExpired, isFalse);
      expect(res.canCancel, isTrue);
      expect(res.statusLabel, 'Đang chờ sách');
      expect(res.notes, 'Lấy vào cuối tuần');
    });

    test('Parse READY reservation with nested book and expiresAt', () {
      final json = {
        'id': 'res-102',
        'reservationNumber': 'RSV-002',
        'member': {'id': 'mem-2', 'fullName': 'Nguyễn Văn A'},
        'book': {'id': 'b-2', 'title': 'Clean Code'},
        'status': 'READY',
        'createdAt': '2026-11-10T08:00:00Z',
        'readyAt': '2026-11-12T09:00:00Z',
        'expiresAt': '2026-11-15T18:00:00Z',
      };

      final res = Reservation.fromJson(json);

      expect(res.id, 'res-102');
      expect(res.memberId, 'mem-2');
      expect(res.bookId, 'b-2');
      expect(res.bookTitle, 'Clean Code');
      expect(res.status, 'READY');
      expect(res.isReady, isTrue);
      expect(res.canCancel, isTrue);
      expect(res.statusLabel, 'Sẵn sàng nhận sách');
      expect(res.readyAt, isNotNull);
      expect(res.expiresAt, isNotNull);
      expect(res.expiresAt!.day, 15);
    });

    test('Parse FULFILLED reservation', () {
      final json = {
        'id': 'res-103',
        'reservationNumber': 'RSV-003',
        'memberId': 'mem-1',
        'bookId': 'b-3',
        'bookTitle': 'Design Patterns',
        'status': 'FULFILLED',
        'reservationDate': '2026-11-01T10:00:00Z',
        'fulfilledAt': '2026-11-05T14:00:00Z',
      };

      final res = Reservation.fromJson(json);

      expect(res.isFulfilled, isTrue);
      expect(res.canCancel, isFalse);
      expect(res.statusLabel, 'Đã nhận sách');
      expect(res.fulfilledAt, isNotNull);
    });

    test('Parse CANCELLED reservation with reason', () {
      final json = {
        'id': 'res-104',
        'reservationNumber': 'RSV-004',
        'memberId': 'mem-1',
        'bookId': 'b-4',
        'bookTitle': 'Refactoring',
        'status': 'CANCELLED',
        'reservationDate': '2026-11-02T10:00:00Z',
        'cancelledAt': '2026-11-03T11:00:00Z',
        'cancellationReason': 'Không còn nhu cầu',
      };

      final res = Reservation.fromJson(json);

      expect(res.isCancelled, isTrue);
      expect(res.canCancel, isFalse);
      expect(res.statusLabel, 'Đã hủy');
      expect(res.cancelledAt, isNotNull);
      expect(res.cancellationReason, 'Không còn nhu cầu');
    });

    test('Parse EXPIRED reservation', () {
      final json = {
        'id': 'res-105',
        'reservationNumber': 'RSV-005',
        'memberId': 'mem-1',
        'bookId': 'b-5',
        'bookTitle': 'Domain-Driven Design',
        'status': 'EXPIRED',
        'reservationDate': '2026-10-20T10:00:00Z',
        'expiresAt': '2026-10-25T18:00:00Z',
      };

      final res = Reservation.fromJson(json);

      expect(res.isExpired, isTrue);
      expect(res.canCancel, isFalse);
      expect(res.statusLabel, 'Hết hạn');
    });

    test('Parse wrapped in { data: ... }', () {
      final raw = {
        'data': {
          'id': 'res-200',
          'reservationNumber': 'RSV-200',
          'memberId': 'mem-1',
          'bookId': 'b-10',
          'bookTitle': 'Microservices Patterns',
          'status': 'PENDING',
          'reservationDate': '2026-11-12T10:00:00Z',
        }
      };

      final res = Reservation.fromJson(raw);
      expect(res.id, 'res-200');
      expect(res.bookTitle, 'Microservices Patterns');
    });

    test('copyWith and toJson roundtrip', () {
      final res = Reservation(
        id: 'res-300',
        reservationNumber: 'RSV-300',
        memberId: 'mem-1',
        bookId: 'b-1',
        bookTitle: 'Test Book',
        status: 'PENDING',
        reservationDate: DateTime.parse('2026-11-12T10:00:00Z'),
        notes: 'Original note',
      );

      final updated = res.copyWith(
        status: 'READY',
        notes: 'Updated note',
      );

      expect(updated.status, 'READY');
      expect(updated.notes, 'Updated note');
      expect(updated.id, 'res-300');

      final json = updated.toJson();
      expect(json['id'], 'res-300');
      expect(json['status'], 'READY');
      expect(json['notes'], 'Updated note');

      final reconstructed = Reservation.fromJson(json);
      expect(reconstructed.id, updated.id);
      expect(reconstructed.status, updated.status);
    });
  });

  group('PaginatedReservations Model', () {
    test('Parse standard paginated response with data and meta', () {
      final json = {
        'data': [
          {
            'id': 'res-1',
            'reservationNumber': 'RSV-1',
            'memberId': 'mem-1',
            'bookId': 'b-1',
            'bookTitle': 'Book 1',
            'status': 'PENDING',
            'reservationDate': '2026-11-12T10:00:00Z',
          },
          {
            'id': 'res-2',
            'reservationNumber': 'RSV-2',
            'memberId': 'mem-1',
            'bookId': 'b-2',
            'bookTitle': 'Book 2',
            'status': 'READY',
            'reservationDate': '2026-11-11T10:00:00Z',
          }
        ],
        'meta': {
          'page': 1,
          'limit': 10,
          'totalItems': 2,
          'totalPages': 1,
          'hasNextPage': false,
        }
      };

      final paginated = PaginatedReservations.fromJson(json);

      expect(paginated.items.length, 2);
      expect(paginated.page, 1);
      expect(paginated.limit, 10);
      expect(paginated.totalItems, 2);
      expect(paginated.totalPages, 1);
      expect(paginated.hasNextPage, isFalse);
    });

    test('Parse paginated response with fallback items and flat meta', () {
      final json = {
        'items': [
          {
            'id': 'res-1',
            'reservationNumber': 'RSV-1',
            'memberId': 'mem-1',
            'bookId': 'b-1',
            'bookTitle': 'Book 1',
            'status': 'PENDING',
            'reservationDate': '2026-11-12T10:00:00Z',
          }
        ],
        'page': 2,
        'limit': 5,
        'total': 12,
      };

      final paginated = PaginatedReservations.fromJson(json);

      expect(paginated.items.length, 1);
      expect(paginated.page, 2);
      expect(paginated.limit, 5);
      expect(paginated.totalItems, 12);
      expect(paginated.totalPages, 3);
      expect(paginated.hasNextPage, isTrue);
    });
  });
}
