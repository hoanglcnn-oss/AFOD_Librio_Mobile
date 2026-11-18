import 'package:flutter/material.dart';

/// Painter vẽ vết khuyết bán nguyệt (Notch cutouts) ở hai mép vé
/// Khoét sâu vào mép card và viền theo đường cong giống như vé giấy đục lỗ thực tế
class TicketNotchPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool isLeft;

  const TicketNotchPainter({
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 1.0,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (isLeft) {
      // Vết khuyết mép trái: phủ lấn ra ngoài mép (-4px) để tẩy sạch hoàn toàn đường viền dọc của card
      final path = Path()
        ..moveTo(-4.0, -1.0)
        ..lineTo(0, 0)
        ..arcToPoint(
          Offset(0, size.height),
          radius: Radius.circular(size.height / 2),
          clockwise: true,
        )
        ..lineTo(-4.0, size.height + 1.0)
        ..close();
      canvas.drawPath(path, fillPaint);

      // Chỉ viền theo đường cong bán nguyệt lõm vào trong (+x), tuyệt đối không vẽ đường dọc thẳng
      final borderPath = Path()
        ..moveTo(0, 0)
        ..arcToPoint(
          Offset(0, size.height),
          radius: Radius.circular(size.height / 2),
          clockwise: true,
        );
      canvas.drawPath(borderPath, borderPaint);
    } else {
      // Vết khuyết mép phải: phủ lấn ra ngoài mép (+4px) để tẩy sạch hoàn toàn đường viền dọc của card
      final path = Path()
        ..moveTo(size.width + 4.0, -1.0)
        ..lineTo(size.width, 0)
        ..arcToPoint(
          Offset(size.width, size.height),
          radius: Radius.circular(size.height / 2),
          clockwise: false,
        )
        ..lineTo(size.width + 4.0, size.height + 1.0)
        ..close();
      canvas.drawPath(path, fillPaint);

      // Chỉ viền theo đường cong bán nguyệt lõm vào trong (-x), tuyệt đối không vẽ đường dọc thẳng
      final borderPath = Path()
        ..moveTo(size.width, 0)
        ..arcToPoint(
          Offset(size.width, size.height),
          radius: Radius.circular(size.height / 2),
          clockwise: false,
        );
      canvas.drawPath(borderPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TicketNotchPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.isLeft != isLeft;
}

/// Đường kẻ nét đứt phong cách vé thư viện (Ticket Pass)
class TicketDashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const TicketDashedDivider({
    super.key,
    this.height = 1.5,
    this.color = const Color(0xFFCBD5E1),
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}

/// Rãnh xé vé hoàn chỉnh: vết khuyết trái + đường nét đứt + vết khuyết phải
class TicketPerforationRow extends StatelessWidget {
  final Color backgroundColor;
  final Color ticketColor;
  final Color borderColor;
  final double borderWidth;
  final double height;

  const TicketPerforationRow({
    super.key,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.ticketColor = Colors.white,
    this.borderColor = const Color(0xFFCBD5E1),
    this.borderWidth = 1.0,
    this.height = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ticketColor,
      height: height,
      child: Row(
        children: [
          CustomPaint(
            size: Size(height / 2, height),
            painter: TicketNotchPainter(
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              borderWidth: borderWidth,
              isLeft: true,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TicketDashedDivider(
              color: borderColor,
            ),
          ),
          const SizedBox(width: 6),
          CustomPaint(
            size: Size(height / 2, height),
            painter: TicketNotchPainter(
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              borderWidth: borderWidth,
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }
}
