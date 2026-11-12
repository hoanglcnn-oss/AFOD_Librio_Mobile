class ReturnSlipItemRequest {
  final String itemId;
  final int quantity;
  final String returnCondition;
  final String? notes;

  const ReturnSlipItemRequest({
    required this.itemId,
    this.quantity = 1,
    this.returnCondition = 'GOOD',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'quantity': quantity,
    'returnCondition': returnCondition,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

class ReturnSlipItemsRequest {
  final List<ReturnSlipItemRequest> items;
  final bool isPaidNow;
  final String? notes;

  const ReturnSlipItemsRequest({
    required this.items,
    this.isPaidNow = false,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'isPaidNow': isPaidNow,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
  };
}

