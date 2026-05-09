import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RadarOverlayPainter extends CustomPainter {
  final double sweepAngle;
  final Offset center;
  final double radius;

  const RadarOverlayPainter({
    required this.sweepAngle,
    required this.center,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawRangeRings(canvas);
    _drawAzimuthLines(canvas);
    _drawSweep(canvas);
    _drawCenterCross(canvas);
  }

  void _drawRangeRings(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, paint);
    }
  }

  void _drawAzimuthLines(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final start = Offset(
        center.dx + math.cos(angle) * radius * 0.05,
        center.dy + math.sin(angle) * radius * 0.05,
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawSweep(Canvas canvas) {
    final sweepRect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
        colors: [
          Colors.transparent,
          AppColors.radarSweep,
          AppColors.radarGreen.withOpacity(0.3),
        ],
        stops: const [0.0, 0.7, 1.0],
        transform: GradientRotation(sweepAngle - 0.8),
      ).createShader(sweepRect)
      ..style = PaintingStyle.fill;

    canvas.drawArc(sweepRect, sweepAngle - 0.8, 0.8, true, sweepPaint);

    final linePaint = Paint()
      ..color = AppColors.radarGreen.withOpacity(0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      center,
      Offset(center.dx + math.cos(sweepAngle) * radius, center.dy + math.sin(sweepAngle) * radius),
      linePaint,
    );
  }

  void _drawCenterCross(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..strokeWidth = 1.0;
    const crossSize = 8.0;
    canvas.drawLine(Offset(center.dx - crossSize, center.dy), Offset(center.dx + crossSize, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - crossSize), Offset(center.dx, center.dy + crossSize), paint);

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, dotPaint);
  }

  @override
  bool shouldRepaint(RadarOverlayPainter oldDelegate) =>
      oldDelegate.sweepAngle != sweepAngle;
}

class GridOverlayPainter extends CustomPainter {
  const GridOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridColor
      ..strokeWidth = 0.3;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridOverlayPainter oldDelegate) => false;
}
