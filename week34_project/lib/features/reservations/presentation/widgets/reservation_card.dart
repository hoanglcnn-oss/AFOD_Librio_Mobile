import 'package:flutter/material.dart';

import '../../data/models/reservation.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onCancel;
  final VoidCallback? onCreateSlip;
  final bool isCancelling;
  final bool isOwner;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onCancel,
    this.onCreateSlip,
    this.isCancelling = false,
    this.isOwner = true,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa xác định';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d/$m/$y';
  }

  String _formatDateTime(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Color _getStatusColor(BuildContext context) {
    switch (reservation.status) {
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'READY':
        return const Color(0xFF16A34A);
      case 'FULFILLED':
        return const Color(0xFF0D9488);
      case 'CANCELLED':
        return const Color(0xFF64748B);
      case 'EXPIRED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusBgColor(BuildContext context) {
    switch (reservation.status) {
      case 'PENDING':
        return const Color(0xFFFFFBEB);
      case 'READY':
        return const Color(0xFFF0FDF4);
      case 'FULFILLED':
        return const Color(0xFFF0FDFA);
      case 'CANCELLED':
        return const Color(0xFFF1F5F9);
      case 'EXPIRED':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  Color _getStatusBorderColor(BuildContext context) {
    switch (reservation.status) {
      case 'PENDING':
        return const Color(0xFFFDE68A);
      case 'READY':
        return const Color(0xFFBBF7D0);
      case 'FULFILLED':
        return const Color(0xFFCCFBF1);
      case 'CANCELLED':
        return const Color(0xFFE2E8F0);
      case 'EXPIRED':
        return const Color(0xFFFECACA);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final statusBgColor = _getStatusBgColor(context);
    final statusBorderColor = _getStatusBorderColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: reservation.isReady
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFE2E8F0),
          width: reservation.isReady ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Code and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Mã phiếu: ${reservation.reservationCode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusBorderColor),
                  ),
                  child: Text(
                    reservation.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Book Title
            Text(
              reservation.bookTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 8),

            // Ngày đặt
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Ngày đặt: ${_formatDate(reservation.reservedAt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            // Ready notice & expiry
            if (reservation.isReady) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF16A34A),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Sách đã sẵn sàng để lấy!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (reservation.expiresAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Hạn lấy sách: ${_formatDateTime(reservation.expiresAt!)}',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Pending info
            if (reservation.isPending) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(
                    Icons.hourglass_top,
                    size: 15,
                    color: Color(0xFFD97706),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Đang chờ sách có sẵn từ thư viện',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Notes
            if (reservation.notes != null &&
                reservation.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ghi chú: ${reservation.notes}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            // Cancellation reason (if cancelled)
            if (reservation.isCancelled &&
                reservation.cancellationReason != null &&
                reservation.cancellationReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Lý do hủy: ${reservation.cancellationReason}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],

            // Actions row: Nút Tạo phiếu mượn (chỉ READY) và Hủy đặt trước (PENDING/READY) thuộc MEMBER
            if ((reservation.canCancel || (reservation.isReady && onCreateSlip != null)) && isOwner) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (reservation.isReady && onCreateSlip != null) ...[
                    FilledButton.icon(
                      key: ValueKey('create_slip_btn_${reservation.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: isCancelling ? null : onCreateSlip,
                      icon: const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 16,
                      ),
                      label: const Text('Tạo phiếu mượn'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (reservation.canCancel) ...[
                    if (isCancelling)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        key: ValueKey('cancel_btn_${reservation.id}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(
                            color: Color(0xFFFECACA),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Hủy đặt trước'),
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
