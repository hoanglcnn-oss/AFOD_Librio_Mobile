class BorrowingSlipItem {
  final String id;
  final String bookId;
  final String bookTitle;
  final int quantity;
  final String status;

  const BorrowingSlipItem({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.quantity,
    required this.status,
  });

  factory BorrowingSlipItem.fromJson(Map<String, dynamic> json) {
    return BorrowingSlipItem(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      quantity: (json['quantity'] as num).toInt(),
      status: json['status'] as String,
    );
  }
}

class BorrowingSlip {
  final String id;
  final String slipNumber;
  final String memberId;
  final String status;
  final DateTime dueDate;
  final List<BorrowingSlipItem> items;

  const BorrowingSlip({
    required this.id,
    required this.slipNumber,
    required this.memberId,
    required this.status,
    required this.dueDate,
    required this.items,
  });

  factory BorrowingSlip.fromJson(Map<String, dynamic> json) {
    return BorrowingSlip(
      id: json['id'] as String,
      slipNumber: json['slipNumber'] as String,
      memberId: json['memberId'] as String,
      status: json['status'] as String,

      dueDate: DateTime.parse(json['dueDate'] as String),

      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) =>
                    BorrowingSlipItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
