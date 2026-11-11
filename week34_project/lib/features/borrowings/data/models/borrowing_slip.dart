class BorrowingSlipItem {
  final String id;
  final String bookId;
  final String bookTitle;
  final int quantity;
  final String status;

  final int returnedQuantity;
  final int lostQuantity;
  final DateTime? returnDate;
  final String? returnCondition;
  final double lateFee;
  final double compensationFee;
  final double fineAmount;

  const BorrowingSlipItem({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.quantity,
    required this.status,
    this.returnedQuantity = 0,
    this.lostQuantity = 0,
    this.returnDate,
    this.returnCondition,
    this.lateFee = 0,
    this.compensationFee = 0,
    this.fineAmount = 0,
  });

  int get remainingQuantity => quantity - returnedQuantity - lostQuantity;

  factory BorrowingSlipItem.fromJson(Map<String, dynamic> json) {
    return BorrowingSlipItem(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      quantity: (json['quantity'] as num).toInt(),
      status: json['status'] as String,
      returnedQuantity: (json['returnedQuantity'] as num?)?.toInt() ?? 0,
      lostQuantity: (json['lostQuantity'] as num?)?.toInt() ?? 0,
      returnDate: _parseDate(json['returnDate']),
      returnCondition: json['returnCondition'] as String?,
      lateFee: (json['lateFee'] as num?)?.toDouble() ?? 0,
      compensationFee: (json['compensationFee'] as num?)?.toDouble() ?? 0,
      fineAmount: (json['fineAmount'] as num?)?.toDouble() ?? 0,
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

  final DateTime? borrowDate;
  final DateTime? approvedAt;
  final double totalFine;
  final bool finePaid;
  final DateTime? finePaidAt;
  final int renewCount;

  const BorrowingSlip({
    required this.id,
    required this.slipNumber,
    required this.memberId,
    required this.status,
    required this.dueDate,
    required this.items,
    this.borrowDate,
    this.approvedAt,
    this.totalFine = 0,
    this.finePaid = false,
    this.finePaidAt,
    this.renewCount = 0,
  });

  factory BorrowingSlip.fromJson(Map<String, dynamic> json) {
    return BorrowingSlip(
      id: json['id'] as String,
      slipNumber: json['slipNumber'] as String,
      memberId: json['memberId'] as String,
      status: json['status'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      borrowDate: _parseDate(json['borrowDate']),
      approvedAt: _parseDate(json['approvedAt']),
      totalFine: (json['totalFine'] as num?)?.toDouble() ?? 0,
      finePaid: json['finePaid'] as bool? ?? false,
      finePaidAt: _parseDate(json['finePaidAt']),
      renewCount: (json['renewCount'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map(
            (item) => BorrowingSlipItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.parse(value as String);
}
