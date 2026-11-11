import '../../data/models/borrowing_slip.dart';

//format, status, overdue
class BorrowingSlipUiHelper {
  BorrowingSlipUiHelper._();

  static String formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String formatMoney(num value) {
    final digits = value.round().toString();
    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} VNĐ';
  }

  static String slipStatus(String status) {
    return switch (status) {
      'PENDING_APPROVAL' => 'Chờ duyệt',
      'BORROWED' => 'Đang mượn',
      'PARTIAL_RETURNED' => 'Đã trả một phần',
      'COMPLETED' => 'Đã hoàn tất',
      'REJECTED' => 'Bị từ chối',
      'CANCELLED' => 'Đã hủy',
      _ => status,
    };
  }

  static String itemStatus(String status) {
    return switch (status) {
      'PENDING' => 'Chờ duyệt',
      'BORROWING' => 'Đang mượn',
      'RETURNED' => 'Đã trả',
      'LOST' => 'Đã báo mất',
      _ => status,
    };
  }

  static bool isOverdue(BorrowingSlip slip, {DateTime? now}) {
    if (slip.status != 'BORROWED' && slip.status != 'PARTIAL_RETURNED') {
      return false;
    }

    if (!slip.items.any((item) => item.remainingQuantity > 0)) {
      return false;
    }

    final current = (now ?? DateTime.now()).toLocal();
    final due = slip.dueDate.toLocal();

    final today = DateTime(current.year, current.month, current.day);

    final dueDay = DateTime(due.year, due.month, due.day);

    return today.isAfter(dueDay);
  }

  static bool hasUnpaidFine(BorrowingSlip slip) {
    return slip.totalFine > 0 && !slip.finePaid;
  }
}
