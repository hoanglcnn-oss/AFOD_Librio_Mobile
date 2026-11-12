import 'borrowing_slip.dart';

class PaginatedBorrowingSlips {
  final List<BorrowingSlip> slips;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;

  const PaginatedBorrowingSlips({
    required this.slips,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory PaginatedBorrowingSlips.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;

    return PaginatedBorrowingSlips(
      slips: (json['data'] as List<dynamic>)
          .map((item) => BorrowingSlip.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: (meta['page'] as num).toInt(),
      limit: (meta['limit'] as num).toInt(),
      totalItems: (meta['totalItems'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
      hasNextPage: meta['hasNextPage'] as bool,
    );
  }
}
