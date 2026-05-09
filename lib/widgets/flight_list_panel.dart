import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flight.dart';
import '../services/flight_provider.dart';
import '../theme/app_theme.dart';
import 'hud_border.dart';

class FlightListPanel extends StatelessWidget {
  const FlightListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _FilterBar(provider),
            const SizedBox(height: 4),
            _StatusFilterRow(provider),
            const SizedBox(height: 4),
            Expanded(child: _FlightList(provider)),
          ],
        );
      },
    );
  }
}

class _FilterBar extends StatefulWidget {
  final FlightProvider provider;
  const _FilterBar(this.provider);

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HudBorder(
      label: 'SEARCH',
      color: AppColors.borderBright,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _controller,
        onChanged: widget.provider.setFilter,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontFamily: 'monospace'),
        decoration: InputDecoration(
          hintText: 'CALLSIGN / ICAO / COUNTRY',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          border: InputBorder.none,
          isDense: true,
          prefixIcon: const Icon(Icons.search, color: AppColors.textDim, size: 14),
          suffixIcon: _controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.provider.setFilter('');
                  },
                  child: const Icon(Icons.close, color: AppColors.textDim, size: 14),
                )
              : null,
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  final FlightProvider provider;
  const _StatusFilterRow(this.provider);

  @override
  Widget build(BuildContext context) {
    final filters = ['ALL', 'CRUISE', 'CLIMB', 'DESCEND', 'GROUND'];
    return SizedBox(
      height: 22,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final isActive = provider.statusFilter == f;
          return GestureDetector(
            onTap: () => provider.setStatusFilter(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.textDim,
                  fontSize: 8,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlightList extends StatelessWidget {
  final FlightProvider provider;
  const _FlightList(this.provider);

  @override
  Widget build(BuildContext context) {
    final flights = provider.flights;

    if (provider.isLoading && flights.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 8),
            Text('ACQUIRING TARGETS...', style: TextStyle(color: AppColors.textDim, fontSize: 9, letterSpacing: 1.5)),
          ],
        ),
      );
    }

    if (flights.isEmpty) {
      return const Center(
        child: Text('NO CONTACTS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5)),
      );
    }

    return ListView.builder(
      itemCount: flights.length,
      itemBuilder: (ctx, i) => _FlightRow(
        flight: flights[i],
        isSelected: provider.selectedFlight?.icao24 == flights[i].icao24,
        onTap: () => provider.selectFlight(
          provider.selectedFlight?.icao24 == flights[i].icao24 ? null : flights[i],
        ),
      ),
    );
  }
}

class _FlightRow extends StatelessWidget {
  final Flight flight;
  final bool isSelected;
  final VoidCallback onTap;

  const _FlightRow({required this.flight, required this.isSelected, required this.onTap});

  Color get _statusColor {
    switch (flight.flightStatus) {
      case 'CRUISE': return AppColors.primary;
      case 'CLIMB': return AppColors.accent;
      case 'DESCEND': return AppColors.warning;
      case 'GROUND': return AppColors.textDim;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface.withOpacity(0.3),
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.warning : _statusColor.withOpacity(0.4),
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flight.displayCallsign,
                    style: TextStyle(
                      color: isSelected ? AppColors.warning : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    flight.originCountry ?? '???',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 8, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  flight.altitudeDisplay,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontFamily: 'monospace'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  color: _statusColor.withOpacity(0.1),
                  child: Text(
                    flight.flightStatus,
                    style: TextStyle(color: _statusColor, fontSize: 7, letterSpacing: 1.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
