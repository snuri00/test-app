import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HudBorder extends StatelessWidget {
  final Widget child;
  final String? label;
  final Color color;
  final double borderWidth;
  final EdgeInsets padding;
  final bool showCorners;

  const HudBorder({
    super.key,
    required this.child,
    this.label,
    this.color = AppColors.border,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(8),
    this.showCorners = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HudBorderPainter(
        color: color,
        borderWidth: borderWidth,
        label: label,
        showCorners: showCorners,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _HudBorderPainter extends CustomPainter {
  final Color color;
  final double borderWidth;
  final String? label;
  final bool showCorners;

  _HudBorderPainter({
    required this.color,
    required this.borderWidth,
    this.label,
    required this.showCorners,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);

    if (showCorners) {
      final cornerSize = 12.0;
      final cornerPaint = Paint()
        ..color = color.withOpacity(0.9)
        ..strokeWidth = borderWidth + 1
        ..style = PaintingStyle.stroke;

      // Top-left
      canvas.drawLine(Offset(0, cornerSize), Offset(0, 0), cornerPaint);
      canvas.drawLine(Offset(0, 0), Offset(cornerSize, 0), cornerPaint);
      // Top-right
      canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), cornerPaint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), cornerPaint);
      // Bottom-left
      canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), cornerPaint);
      canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), cornerPaint);
      // Bottom-right
      canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), cornerPaint);
      canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), cornerPaint);
    }

    if (label != null) {
      final textSpan = TextSpan(
        text: ' $label ',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontFamily: 'monospace',
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      final bgPaint = Paint()..color = AppColors.background;
      canvas.drawRect(
        Rect.fromLTWH(8, -textPainter.height / 2, textPainter.width, textPainter.height),
        bgPaint,
      );
      textPainter.paint(canvas, Offset(8, -textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_HudBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.label != label;
}
