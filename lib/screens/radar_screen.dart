import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/flight.dart';
import '../services/flight_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hud_border.dart';
import '../widgets/radar_painter.dart';
import '../widgets/flight_marker.dart';
import '../widgets/flight_list_panel.dart';
import '../widgets/flight_detail_panel.dart';
import '../widgets/status_bar.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late MapController _mapController;
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  bool _showRadarOverlay = true;
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlightProvider>().startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _sweepController.dispose();
    context.read<FlightProvider>().stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TopStatusBar(),
          Expanded(
            child: Row(
              children: [
                if (_showLeftPanel) _buildLeftPanel(),
                Expanded(child: _buildMapArea()),
                if (_showRightPanel) _buildRightPanel(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          _PanelHeader(title: 'CONTACT LIST', icon: Icons.radar),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: const FlightListPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(left: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          _PanelHeader(title: 'TARGET DATA', icon: Icons.info_outline),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: const FlightDetailPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return Stack(
      children: [
        _buildMap(),
        if (_showGrid)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: const GridOverlayPainter()),
            ),
          ),
        if (_showRadarOverlay) _buildRadarOverlay(),
        _buildMapControls(),
        _buildCoordinateDisplay(),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildMap() {
    return Consumer<FlightProvider>(
      builder: (context, provider, _) {
        final flights = provider.allFlights.where((f) => f.hasPosition).toList();

        return FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(45.0, 20.0),
            initialZoom: 4.5,
            backgroundColor: AppColors.background,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.flight_radar',
              tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.1, 0.2, 0.8, 0, 0,
                  0.1, 0.2, 0.8, 0, 0,
                  0.2, 0.3, 0.9, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: tileWidget,
              ),
            ),
            MarkerLayer(
              markers: flights.map((flight) {
                final isSelected = provider.selectedFlight?.icao24 == flight.icao24;
                return Marker(
                  point: LatLng(flight.latitude!, flight.longitude!),
                  width: 28,
                  height: 28,
                  child: FlightMarkerWidget(
                    flight: flight,
                    isSelected: isSelected,
                    onTap: () {
                      provider.selectFlight(
                        isSelected ? null : flight,
                      );
                      if (!isSelected && flight.hasPosition) {
                        _mapController.move(
                          LatLng(flight.latitude!, flight.longitude!),
                          _mapController.camera.zoom,
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadarOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _sweepController,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                final radius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.45;
                return CustomPaint(
                  painter: RadarOverlayPainter(
                    sweepAngle: _sweepController.value * 2 * math.pi,
                    center: center,
                    radius: radius,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 8,
      top: 8,
      child: Column(
        children: [
          _ControlButton(
            icon: Icons.add,
            onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
            tooltip: 'ZOOM IN',
          ),
          const SizedBox(height: 4),
          _ControlButton(
            icon: Icons.remove,
            onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
            tooltip: 'ZOOM OUT',
          ),
          const SizedBox(height: 8),
          _ControlButton(
            icon: Icons.grid_on,
            onTap: () => setState(() => _showGrid = !_showGrid),
            tooltip: 'GRID',
            active: _showGrid,
          ),
          const SizedBox(height: 4),
          _ControlButton(
            icon: Icons.radar,
            onTap: () => setState(() => _showRadarOverlay = !_showRadarOverlay),
            tooltip: 'RADAR',
            active: _showRadarOverlay,
          ),
          const SizedBox(height: 4),
          _ControlButton(
            icon: Icons.view_sidebar,
            onTap: () => setState(() => _showLeftPanel = !_showLeftPanel),
            tooltip: 'LIST',
            active: _showLeftPanel,
          ),
          const SizedBox(height: 4),
          _ControlButton(
            icon: Icons.info,
            onTap: () => setState(() => _showRightPanel = !_showRightPanel),
            tooltip: 'INFO',
            active: _showRightPanel,
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateDisplay() {
    return Positioned(
      left: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.panel.withOpacity(0.85),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: AnimatedBuilder(
          animation: _sweepController,
          builder: (_, __) => Text(
            'MAP ZOOM: ${_mapController.camera.zoom.toStringAsFixed(1)}',
            style: const TextStyle(color: AppColors.textDim, fontSize: 8, letterSpacing: 1.0),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Positioned(
      left: 8,
      top: 8,
      child: Consumer<FlightProvider>(
        builder: (context, provider, _) {
          return GestureDetector(
            onTap: provider.isLoading ? null : provider.fetchFlights,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.panel.withOpacity(0.9),
                border: Border.all(
                  color: provider.isLoading ? AppColors.warning : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.isLoading)
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.warning),
                    )
                  else
                    const Icon(Icons.refresh, color: AppColors.textDim, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    provider.isLoading ? 'SYNCING...' : 'REFRESH',
                    style: TextStyle(
                      color: provider.isLoading ? AppColors.warning : AppColors.textDim,
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Consumer<FlightProvider>(
        builder: (context, provider, _) {
          return Row(
            children: [
              const Text(
                'DATA: OPENSKY NETWORK  |  UPDATE: 30s  |  MAP: CARTO DARK',
                style: TextStyle(color: AppColors.textMuted, fontSize: 8, letterSpacing: 1.0),
              ),
              const Spacer(),
              if (provider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.danger.withOpacity(0.15),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 8, letterSpacing: 1.0),
                  ),
                )
              else
                Text(
                  'SYSTEM NOMINAL',
                  style: const TextStyle(color: AppColors.accentDim, fontSize: 8, letterSpacing: 1.5),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PanelHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 12),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const Spacer(),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withOpacity(0.1) : AppColors.panel,
            border: Border.all(
              color: active ? AppColors.primary.withOpacity(0.5) : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            color: active ? AppColors.primary : AppColors.textDim,
            size: 14,
          ),
        ),
      ),
    );
  }
}
