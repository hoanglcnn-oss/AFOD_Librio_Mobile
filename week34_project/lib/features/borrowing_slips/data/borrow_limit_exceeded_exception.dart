class BorrowLimitExceededException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const BorrowLimitExceededException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => message;
}

