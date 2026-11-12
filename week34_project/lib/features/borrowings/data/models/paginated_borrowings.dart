import 'borrowing.dart';

class PaginatedBorrowings {
  final List<Borrowing> borrowings;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;

  const PaginatedBorrowings({
    required this.borrowings,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory PaginatedBorrowings.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;

    return PaginatedBorrowings(
      borrowings: (json['data'] as List<dynamic>)
          .map((item) => Borrowing.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: (meta['page'] as num).toInt(),
      limit: (meta['limit'] as num).toInt(),
      totalItems: (meta['totalItems'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
      hasNextPage: meta['hasNextPage'] as bool,
    );
  }
}
