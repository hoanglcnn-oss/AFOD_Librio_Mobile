class BorrowingSlipItemRequest {
  final String bookId;
  final int quantity;

  const BorrowingSlipItemRequest({
    required this.bookId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {'bookId': bookId, 'quantity': quantity};
  }
}

class CreateBorrowingSlipRequest {
  final String memberId;
  final List<BorrowingSlipItemRequest> items;
  final int expectedReturnDays;
  final String? notes;

  const CreateBorrowingSlipRequest({
    required this.memberId,
    required this.items,
    this.expectedReturnDays = 14,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'items': items.map((item) => item.toJson()).toList(),
      'expectedReturnDays': expectedReturnDays,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
