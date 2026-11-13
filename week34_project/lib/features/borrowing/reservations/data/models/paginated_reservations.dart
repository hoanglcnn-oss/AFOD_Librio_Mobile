import 'reservation.dart';

class PaginatedReservations {
  final List<Reservation> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;

  const PaginatedReservations({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory PaginatedReservations.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] ?? json['items'] ?? json['reservations'] ?? [];
    final items = (rawList as List<dynamic>)
        .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : json;

    final page = (meta['page'] as num?)?.toInt() ?? 1;
    final limit = (meta['limit'] as num?)?.toInt() ?? 10;
    final totalItems = (meta['totalItems'] as num?)?.toInt() ??
        (meta['total'] as num?)?.toInt() ??
        items.length;
    final totalPages = (meta['totalPages'] as num?)?.toInt() ??
        ((totalItems > 0 && limit > 0) ? (totalItems / limit).ceil() : 1);
    final hasNextPage = (meta['hasNextPage'] as bool?) ?? (page < totalPages);

    return PaginatedReservations(
      items: items,
      page: page,
      limit: limit,
      totalItems: totalItems,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
    );
  }
}
