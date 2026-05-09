import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/flight_provider.dart';
import '../theme/app_theme.dart';

class TopStatusBar extends StatefulWidget {
  const TopStatusBar({super.key});

  @override
  State<TopStatusBar> createState() => _TopStatusBarState();
}

class _TopStatusBarState extends State<TopStatusBar> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.panel,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _SystemLabel(),
              const SizedBox(width: 16),
              _StatusIndicator(provider),
              const Spacer(),
              _StatChip('TRACKED', '${provider.totalCount}', AppColors.primary),
              const SizedBox(width: 8),
              _StatChip('AIRBORNE', '${provider.airborne}', AppColors.accent),
              const SizedBox(width: 8),
              _StatChip('GROUND', '${provider.onGround}', AppColors.textDim),
              const SizedBox(width: 16),
              _ClockDisplay(_now),
            ],
          ),
        );
      },
    );
  }
}

class _SystemLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.6), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'SKYWATCH ATC v2.1',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final FlightProvider provider;
  const _StatusIndicator(this.provider);

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (provider.status) {
      case FetchStatus.loading:
        color = AppColors.warning;
        text = 'SYNCING';
        break;
      case FetchStatus.success:
        color = AppColors.accent;
        text = 'LIVE';
        break;
      case FetchStatus.error:
      case FetchStatus.rateLimited:
        color = AppColors.danger;
        text = 'ERR';
        break;
      default:
        color = AppColors.textDim;
        text = 'IDLE';
    }

    return Row(
      children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace', letterSpacing: 1.5),
        ),
        if (provider.lastUpdate != null) ...[
          const SizedBox(width: 6),
          Text(
            DateFormat('HH:mm:ss').format(provider.lastUpdate!),
            style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontFamily: 'monospace'),
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 8, letterSpacing: 1.2)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

class _ClockDisplay extends StatelessWidget {
  final DateTime now;
  const _ClockDisplay(this.now);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('UTC ', style: TextStyle(color: AppColors.textDim, fontSize: 8, letterSpacing: 1)),
        Text(
          DateFormat('HH:mm:ss').format(now),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat('yyyy-MM-dd').format(now),
          style: const TextStyle(color: AppColors.textDim, fontSize: 9, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
