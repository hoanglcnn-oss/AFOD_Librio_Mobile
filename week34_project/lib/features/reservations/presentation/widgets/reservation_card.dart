import 'package:flutter/material.dart';

import '../../data/models/reservation.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onCancel;
  final bool isCancelling;
  final bool isOwner;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onCancel,
    this.isCancelling = false,
    this.isOwner = true,
  });

  String _formatDate(DateTime date) {
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
        return Colors.orange.shade700;
      case 'READY':
        return Colors.green.shade700;
      case 'FULFILLED':
        return Colors.blue.shade700;
      case 'CANCELLED':
        return Colors.grey.shade600;
      case 'EXPIRED':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(BuildContext context) {
    switch (reservation.status) {
      case 'PENDING':
        return Colors.orange.shade50;
      case 'READY':
        return Colors.green.shade50;
      case 'FULFILLED':
        return Colors.blue.shade50;
      case 'CANCELLED':
        return Colors.grey.shade100;
      case 'EXPIRED':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);
    final statusBgColor = _getStatusBgColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: reservation.isReady
              ? Colors.green.shade300
              : Colors.grey.shade200,
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
                    'Mã phiếu: ${reservation.reservationNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
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
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
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
              ),
            ),

            const SizedBox(height: 8),

            // Ngày đặt
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Ngày đặt: ${_formatDate(reservation.reservationDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            // Ready notice & expiry
            if (reservation.isReady) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Sách đã sẵn sàng để lấy!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (reservation.expiresAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Hạn lấy sách: ${_formatDateTime(reservation.expiresAt!)}',
                        style: TextStyle(
                          color: Colors.green.shade900,
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
                children: [
                  Icon(Icons.hourglass_top,
                      size: 15, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Đang chờ sách có sẵn từ thư viện',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
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
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            // Actions row: Nút Hủy đặt trước chỉ với PENDING/READY thuộc MEMBER
            if (reservation.canCancel && isOwner) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: isCancelling
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton.icon(
                        key: ValueKey('cancel_btn_${reservation.id}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Hủy đặt trước'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
