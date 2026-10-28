class CreateBorrowingRequest {
  final String memberId;
  final String bookId;
  final int durationDays;
  final String? notes;

  const CreateBorrowingRequest({
    required this.memberId,
    required this.bookId,
    this.durationDays = 14,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'bookId': bookId,
      'durationDays': durationDays,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }
}
