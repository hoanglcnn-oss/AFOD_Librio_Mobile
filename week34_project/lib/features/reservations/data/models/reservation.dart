class Reservation {
  final String id;
  final String reservationNumber;
  final String memberId;
  final String bookId;
  final String bookTitle;
  final String status;
  final DateTime reservationDate;
  final DateTime? readyAt;
  final DateTime? expiresAt;
  final DateTime? fulfilledAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? notes;

  const Reservation({
    required this.id,
    required this.reservationNumber,
    required this.memberId,
    required this.bookId,
    required this.bookTitle,
    required this.status,
    required this.reservationDate,
    this.readyAt,
    this.expiresAt,
    this.fulfilledAt,
    this.cancelledAt,
    this.cancellationReason,
    this.notes,
  });

  bool get isPending => status == 'PENDING';
  bool get isReady => status == 'READY';
  bool get isFulfilled => status == 'FULFILLED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isExpired => status == 'EXPIRED';
  bool get canCancel => isPending || isReady;

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Đang chờ sách';
      case 'READY':
        return 'Sẵn sàng nhận sách';
      case 'FULFILLED':
        return 'Đã nhận sách';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'EXPIRED':
        return 'Hết hạn';
      default:
        return status;
    }
  }

  factory Reservation.fromJson(Map<String, dynamic> raw) {
    final json = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw;

    final rawBookId = json['bookId'] ??
        (json['book'] is Map ? json['book']['id'] : null) ??
        '';
    final bookId = rawBookId.toString();

    final rawTitle = json['bookTitle'] ??
        (json['book'] is Map ? json['book']['title'] : null) ??
        (json['book'] is Map ? json['book']['name'] : null);
    final bookTitle = rawTitle != null ? rawTitle.toString() : 'Sách #$bookId';

    final rawMemberId = json['memberId'] ??
        (json['member'] is Map ? json['member']['id'] : null) ??
        '';
    final memberId = rawMemberId.toString();

    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final reservationNumber = (json['reservationNumber'] ??
            json['code'] ??
            json['id'] ??
            '')
        .toString();

    final status = (json['status'] ?? 'PENDING').toString().toUpperCase();

    final reservationDate = _parseDate(
          json['reservationDate'] ?? json['createdAt'] ?? json['created_at'],
        ) ??
        DateTime.now();

    return Reservation(
      id: id,
      reservationNumber: reservationNumber,
      memberId: memberId,
      bookId: bookId,
      bookTitle: bookTitle,
      status: status,
      reservationDate: reservationDate,
      readyAt: _parseDate(json['readyAt'] ?? json['ready_at']),
      expiresAt: _parseDate(
        json['expiresAt'] ?? json['expires_at'] ?? json['expiryDate'],
      ),
      fulfilledAt: _parseDate(json['fulfilledAt'] ?? json['fulfilled_at']),
      cancelledAt: _parseDate(json['cancelledAt'] ?? json['cancelled_at']),
      cancellationReason: (json['cancellationReason'] ??
              json['cancelReason'] ??
              json['reason'])
          ?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reservationNumber': reservationNumber,
        'memberId': memberId,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'status': status,
        'reservationDate': reservationDate.toIso8601String(),
        'readyAt': readyAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'fulfilledAt': fulfilledAt?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
        'cancellationReason': cancellationReason,
        'notes': notes,
      };

  Reservation copyWith({
    String? id,
    String? reservationNumber,
    String? memberId,
    String? bookId,
    String? bookTitle,
    String? status,
    DateTime? reservationDate,
    DateTime? readyAt,
    DateTime? expiresAt,
    DateTime? fulfilledAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? notes,
  }) {
    return Reservation(
      id: id ?? this.id,
      reservationNumber: reservationNumber ?? this.reservationNumber,
      memberId: memberId ?? this.memberId,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      status: status ?? this.status,
      reservationDate: reservationDate ?? this.reservationDate,
      readyAt: readyAt ?? this.readyAt,
      expiresAt: expiresAt ?? this.expiresAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      notes: notes ?? this.notes,
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    return null;
  }
}
