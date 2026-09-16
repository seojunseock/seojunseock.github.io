import 'package:flutter/material.dart';

/// A small perforated meal-ticket glyph, drawn to scale rather than pasted
/// as an SVG string — it is the one piece of imagery specific to this app's
/// subject (a physical 식권 stub), so it earns being hand-drawn.
class TicketIcon extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const TicketIcon({
    super.key,
    required this.color,
    this.width = 15,
    this.height = 11,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _TicketPainter(color)),
    );
  }
}

class _TicketPainter extends CustomPainter {
  final Color color;
  _TicketPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.4));

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawRRect(rrect, strokePaint);

    final perforationX = size.width * 0.68;
    const dashHeight = 1.3;
    const gapHeight = 1.3;
    var y = 1.0;
    while (y < size.height - 1) {
      canvas.drawLine(
        Offset(perforationX, y),
        Offset(perforationX, (y + dashHeight).clamp(0, size.height - 1)),
        strokePaint,
      );
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _TicketPainter oldDelegate) =>
      oldDelegate.color != color;
}
