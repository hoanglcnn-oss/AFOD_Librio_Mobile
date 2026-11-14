import 'package:flutter_test/flutter_test.dart';
import 'package:week34_project/features/borrowing/reservations/data/models/paginated_reservations.dart';
import 'package:week34_project/features/borrowing/reservations/data/models/reservation.dart';

void main() {
  group('Reservation Model', () {
    test('Parse thực tế theo Backend contract: reservationCode và reservedAt', () {
      final json = {
        'id': 'res-backend-001',
        'reservationCode': 'RSV-2026-0001',
        'memberId': 'mem-101',
        'bookId': 'b-202',
        'bookTitle': 'Lập trình Flutter chuyên sâu',
        'status': 'PENDING',
        'reservedAt': '2026-11-13T08:30:00.000Z',
        'notes': 'Nhận sách vào buổi chiều',
      };

      final res = Reservation.fromJson(json);

      expect(res.id, 'res-backend-001');
      expect(res.reservationCode, 'RSV-2026-0001');
      expect(res.reservationNumber, 'RSV-2026-0001'); // Alias
      expect(res.memberId, 'mem-101');
      expect(res.bookId, 'b-202');
      expect(res.bookTitle, 'Lập trình Flutter chuyên sâu');
      expect(res.status, 'PENDING');
      expect(res.isPending, isTrue);
      expect(res.isReady, isFalse);
      expect(res.canCancel, isTrue);
      expect(res.statusLabel, 'Đang chờ sách');
      expect(res.reservedAt, DateTime.parse('2026-11-13T08:30:00.000Z'));
      expect(res.reservationDate, DateTime.parse('2026-11-13T08:30:00.000Z')); // Alias
      expect(res.notes, 'Nhận sách vào buổi chiều');
    });

    test('Không dùng DateTime.now() để che dữ liệu thời gian thiếu/sai -> reservedAt là null', () {
      final json = {
        'id': 'res-no-date',
        'reservationCode': 'RSV-NODATE',
        'memberId': 'mem-1',
        'bookId': 'b-1',
        'bookTitle': 'Sách không có ngày',
        'status': 'PENDING',
      };

      final res = Reservation.fromJson(json);

      expect(res.id, 'res-no-date');
      expect(res.reservedAt, isNull);
      expect(res.reservationDate, isNull);
    });

    test('Giữ fallback tương thích: reservationNumber và createdAt', () {
      final json = {
        'id': 'res-fallback',
        'reservationNumber': 'RSV-FALLBACK',
        'memberId': 'mem-1',
        'bookId': 'b-1',
        'bookTitle': 'Sách cũ',
        'status': 'PENDING',
        'createdAt': '2026-11-10T10:00:00Z',
      };

      final res = Reservation.fromJson(json);

      expect(res.reservationCode, 'RSV-FALLBACK');
      expect(res.reservedAt, DateTime.parse('2026-11-10T10:00:00Z'));
    });

    test('Parse READY reservation with nested book and expiresAt', () {
      final json = {
        'id': 'res-102',
        'reservationCode': 'RSV-002',
        'member': {'id': 'mem-2', 'fullName': 'Nguyễn Văn A'},
        'book': {'id': 'b-2', 'title': 'Clean Code'},
        'status': 'READY',
        'reservedAt': '2026-11-10T08:00:00Z',
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
        'reservationCode': 'RSV-003',
        'memberId': 'mem-1',
        'bookId': 'b-3',
        'bookTitle': 'Design Patterns',
        'status': 'FULFILLED',
        'reservedAt': '2026-11-01T10:00:00Z',
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
        'reservationCode': 'RSV-004',
        'memberId': 'mem-1',
        'bookId': 'b-4',
        'bookTitle': 'Refactoring',
        'status': 'CANCELLED',
        'reservedAt': '2026-11-02T10:00:00Z',
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
        'reservationCode': 'RSV-005',
        'memberId': 'mem-1',
        'bookId': 'b-5',
        'bookTitle': 'Domain-Driven Design',
        'status': 'EXPIRED',
        'reservedAt': '2026-10-20T10:00:00Z',
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
          'reservationCode': 'RSV-200',
          'memberId': 'mem-1',
          'bookId': 'b-10',
          'bookTitle': 'Microservices Patterns',
          'status': 'PENDING',
          'reservedAt': '2026-11-12T10:00:00Z',
        }
      };

      final res = Reservation.fromJson(raw);
      expect(res.id, 'res-200');
      expect(res.bookTitle, 'Microservices Patterns');
    });
  });

  group('PaginatedReservations Model', () {
    test('Parse standard paginated response with data and meta', () {
      final json = {
        'data': [
          {
            'id': 'res-1',
            'reservationCode': 'RSV-1',
            'memberId': 'mem-1',
            'bookId': 'b-1',
            'bookTitle': 'Book 1',
            'status': 'PENDING',
            'reservedAt': '2026-11-12T10:00:00Z',
          },
          {
            'id': 'res-2',
            'reservationCode': 'RSV-2',
            'memberId': 'mem-1',
            'bookId': 'b-2',
            'bookTitle': 'Book 2',
            'status': 'READY',
            'reservedAt': '2026-11-11T10:00:00Z',
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
            'reservationCode': 'RSV-1',
            'memberId': 'mem-1',
            'bookId': 'b-1',
            'bookTitle': 'Book 1',
            'status': 'PENDING',
            'reservedAt': '2026-11-12T10:00:00Z',
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
