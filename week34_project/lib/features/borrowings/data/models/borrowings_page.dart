import 'borrowing.dart';

class BorrowingsPage {
  final List<Borrowing> borrowings;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;

  const BorrowingsPage({
    required this.borrowings,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory BorrowingsPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;

    return BorrowingsPage(
      borrowings: (json['data'] as List<dynamic>)
          .map((item) => Borrowing.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int,
      limit: meta['limit'] as int,
      totalItems: meta['totalItems'] as int,
      totalPages: meta['totalPages'] as int,
      hasNextPage: meta['hasNextPage'] as bool,
    );
  }
}
