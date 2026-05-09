import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/flight.dart';
import '../theme/app_theme.dart';

class FlightMarkerWidget extends StatelessWidget {
  final Flight flight;
  final bool isSelected;
  final VoidCallback onTap;

  const FlightMarkerWidget({
    super.key,
    required this.flight,
    required this.isSelected,
    required this.onTap,
  });

  Color get _markerColor {
    if (isSelected) return AppColors.warning;
    if (flight.onGround) return AppColors.textDim;
    switch (flight.threatLevel) {
      case ThreatLevel.high:
        return AppColors.danger;
      case ThreatLevel.medium:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(
          painter: _AircraftPainter(
            angle: flight.trueTrack ?? 0,
            color: _markerColor,
            isSelected: isSelected,
            isOnGround: flight.onGround,
          ),
        ),
      ),
    );
  }
}

class _AircraftPainter extends CustomPainter {
  final double angle;
  final Color color;
  final bool isSelected;
  final bool isOnGround;

  const _AircraftPainter({
    required this.angle,
    required this.color,
    required this.isSelected,
    required this.isOnGround,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate((angle - 90) * math.pi / 180);

    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, 12, glowPaint);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(isSelected ? 0.5 : 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Aircraft silhouette
    path.moveTo(0, -9);        // nose
    path.lineTo(1.5, -4);
    path.lineTo(8, -1);        // right wing tip
    path.lineTo(8, 1);
    path.lineTo(1.5, 0);
    path.lineTo(2, 5);
    path.lineTo(4, 6);         // right tail
    path.lineTo(4, 8);
    path.lineTo(0, 6.5);
    path.lineTo(-4, 8);        // left tail
    path.lineTo(-4, 6);
    path.lineTo(-2, 5);
    path.lineTo(-1.5, 0);
    path.lineTo(-8, 1);        // left wing tip
    path.lineTo(-8, -1);
    path.lineTo(-1.5, -4);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_AircraftPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.isSelected != isSelected;
}
