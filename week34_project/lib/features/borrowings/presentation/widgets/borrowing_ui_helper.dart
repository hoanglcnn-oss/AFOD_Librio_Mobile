class BorrowingUiHelper {
  BorrowingUiHelper._();

  static String formatShortId(String id) {
    final trimmed = id.trim();
    if (trimmed.length <= 12) return trimmed;
    return '${trimmed.substring(0, 8)}...${trimmed.substring(trimmed.length - 4)}';
  }

  static String formatMoney(num value) {
    final digits = value.round().toString();
    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} VNĐ';
  }
}

