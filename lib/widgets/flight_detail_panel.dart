import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flight.dart';
import '../services/flight_provider.dart';
import '../theme/app_theme.dart';
import 'hud_border.dart';

class FlightDetailPanel extends StatelessWidget {
  const FlightDetailPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightProvider>(
      builder: (context, provider, _) {
        final flight = provider.selectedFlight;
        if (flight == null) {
          return const _NoSelectionView();
        }
        return _FlightDetails(flight: flight, provider: provider);
      },
    );
  }
}

class _NoSelectionView extends StatelessWidget {
  const _NoSelectionView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(60, 60),
            painter: _RadarIdlePainter(),
          ),
          const SizedBox(height: 12),
          const Text(
            'NO TARGET SELECTED',
            style: TextStyle(color: AppColors.textDim, fontSize: 9, letterSpacing: 2.0),
          ),
          const SizedBox(height: 4),
          const Text(
            'SELECT A CONTACT FROM MAP OR LIST',
            style: TextStyle(color: AppColors.textMuted, fontSize: 8, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}

class _RadarIdlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, size.width / 2 * i / 3, paint);
    }
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * 4, center.dy + math.sin(angle) * 4),
        Offset(center.dx + math.cos(angle) * size.width / 2, center.dy + math.sin(angle) * size.height / 2),
        paint,
      );
    }
    final dotPaint = Paint()..color = AppColors.textMuted..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, dotPaint);
  }

  @override
  bool shouldRepaint(_RadarIdlePainter oldDelegate) => false;
}

class _FlightDetails extends StatelessWidget {
  final Flight flight;
  final FlightProvider provider;

  const _FlightDetails({required this.flight, required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(flight: flight, onClose: () => provider.selectFlight(null)),
          const SizedBox(height: 8),
          _HeadingIndicator(heading: flight.trueTrack ?? 0),
          const SizedBox(height: 8),
          _DataGrid(flight: flight),
          const SizedBox(height: 8),
          _PositionInfo(flight: flight),
          const SizedBox(height: 8),
          _ThreatAssessment(flight: flight),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Flight flight;
  final VoidCallback onClose;
  const _Header({required this.flight, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return HudBorder(
      label: 'TARGET LOCK',
      color: AppColors.warning,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flight.displayCallsign,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                  ),
                ),
                Text(
                  'ICAO: ${flight.icao24.toUpperCase()}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 9, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                color: AppColors.surface.withOpacity(0.5),
              ),
              child: const Icon(Icons.close, color: AppColors.textDim, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadingIndicator extends StatelessWidget {
  final double heading;
  const _HeadingIndicator({required this.heading});

  @override
  Widget build(BuildContext context) {
    return HudBorder(
      label: 'HDG',
      color: AppColors.border,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CustomPaint(painter: _CompassPainter(heading: heading)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${heading.round()}°',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                _cardinalDirection(heading),
                style: const TextStyle(color: AppColors.textDim, fontSize: 10, letterSpacing: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _cardinalDirection(double heading) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    return directions[((heading + 11.25) / 22.5).floor() % 16];
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;
  const _CompassPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, ringPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(heading * math.pi / 180);

    final needlePaint = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, -radius * 0.8), Offset(0, radius * 0.3), needlePaint);

    final northPaint = Paint()..color = AppColors.accent..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, -radius * 0.8), const Offset(0, 0), northPaint);

    canvas.restore();

    final dotPaint = Paint()..color = AppColors.primary..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, dotPaint);
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) => oldDelegate.heading != heading;
}

class _DataGrid extends StatelessWidget {
  final Flight flight;
  const _DataGrid({required this.flight});

  @override
  Widget build(BuildContext context) {
    return HudBorder(
      label: 'TELEMETRY',
      color: AppColors.border,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _DataCell('ALT', flight.altitudeDisplay, AppColors.primary)),
              const SizedBox(width: 4),
              Expanded(child: _DataCell('SPD', flight.speedDisplay, AppColors.accent)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _DataCell('V/S', _verticalRate, AppColors.textSecondary)),
              const SizedBox(width: 4),
              Expanded(child: _DataCell('STATUS', flight.flightStatus, _statusColor)),
            ],
          ),
          const SizedBox(height: 4),
          _DataCell('ORIGIN', flight.originCountry ?? 'UNKNOWN', AppColors.textSecondary),
        ],
      ),
    );
  }

  String get _verticalRate {
    if (flight.verticalRate == null) return 'N/A';
    final rate = flight.verticalRate!;
    final fpm = (rate * 196.85).round();
    return '${rate >= 0 ? '+' : ''}$fpm fpm';
  }

  Color get _statusColor {
    switch (flight.flightStatus) {
      case 'CRUISE': return AppColors.primary;
      case 'CLIMB': return AppColors.accent;
      case 'DESCEND': return AppColors.warning;
      case 'GROUND': return AppColors.textDim;
      default: return AppColors.textSecondary;
    }
  }
}

class _DataCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _DataCell(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        border: Border.all(color: AppColors.border.withOpacity(0.4), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 7, letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}

class _PositionInfo extends StatelessWidget {
  final Flight flight;
  const _PositionInfo({required this.flight});

  @override
  Widget build(BuildContext context) {
    return HudBorder(
      label: 'POSITION',
      color: AppColors.border,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _DataCell('LAT', _formatCoord(flight.latitude, 'N', 'S'), AppColors.textSecondary)),
              const SizedBox(width: 4),
              Expanded(child: _DataCell('LON', _formatCoord(flight.longitude, 'E', 'W'), AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCoord(double? val, String pos, String neg) {
    if (val == null) return 'N/A';
    final dir = val >= 0 ? pos : neg;
    final abs = val.abs();
    final deg = abs.floor();
    final min = ((abs - deg) * 60).floor();
    final sec = ((abs - deg - min / 60) * 3600).round();
    return "$deg°${min.toString().padLeft(2, '0')}'${sec.toString().padLeft(2, '0')}\"$dir";
  }
}

class _ThreatAssessment extends StatelessWidget {
  final Flight flight;
  const _ThreatAssessment({required this.flight});

  @override
  Widget build(BuildContext context) {
    Color threatColor;
    String threatText;
    String threatDesc;

    switch (flight.threatLevel) {
      case ThreatLevel.high:
        threatColor = AppColors.danger;
        threatText = 'HIGH';
        threatDesc = 'LOW ALTITUDE - MONITOR';
        break;
      case ThreatLevel.medium:
        threatColor = AppColors.warning;
        threatText = 'MEDIUM';
        threatDesc = 'APPROACH ALTITUDE';
        break;
      case ThreatLevel.none:
        threatColor = AppColors.textDim;
        threatText = 'NONE';
        threatDesc = 'AIRCRAFT ON GROUND';
        break;
      default:
        threatColor = AppColors.accent;
        threatText = 'LOW';
        threatDesc = 'NORMAL OPERATIONS';
    }

    return HudBorder(
      label: 'ASSESSMENT',
      color: threatColor.withOpacity(0.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: threatColor.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  threatText,
                  style: TextStyle(color: threatColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                ),
                Text('THREAT', style: TextStyle(color: threatColor.withOpacity(0.6), fontSize: 7, letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              threatDesc,
              style: TextStyle(color: threatColor.withOpacity(0.8), fontSize: 9, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
