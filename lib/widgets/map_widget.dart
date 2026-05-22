import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/app_state.dart';
import '../models/service.dart';

class MapWidget extends StatefulWidget {
  final bool showServices;
  final bool isStatic; // if true, doesn't allow pan/zoom

  const MapWidget({
    Key? key,
    this.showServices = true,
    this.isStatic = false,
  }) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);

    // If tracking is active and we have user coords, center map smoothly
    if (state.locationReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapController.camera.center.latitude != state.userLat ||
            _mapController.camera.center.longitude != state.userLng) {
          _mapController.move(
            LatLng(state.userLat, state.userLng),
            _mapController.camera.zoom,
          );
        }
      });
    }

    final userLatLng = LatLng(state.userLat, state.userLng);

    // Dynamic tile styling: sleek futuristic CartoDB Dark or beautiful Light Voyager tiles
    final String tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

    // Prepare list of markers
    final List<Marker> markers = [];

    // 1. User Position Marker
    if (state.locationReady) {
      markers.add(
        Marker(
          point: userLatLng,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 20 + (25 * _pulseController.value),
                    height: 20 + (25 * _pulseController.value),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.3 * (1 - _pulseController.value)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // 2. Services Markers
    if (widget.showServices) {
      for (var service in state.filteredServices) {
        final sLat = state.userLat + service.mockLatOffset;
        final sLng = state.userLng + service.mockLngOffset;
        final isSelected = state.selectedService?.id == service.id;

        Color beaconColor;
        switch (service.category) {
          case ServiceCategory.hospital:
          case ServiceCategory.ambulance:
            beaconColor = Colors.redAccent;
            break;
          case ServiceCategory.police:
            beaconColor = Colors.cyan;
            break;
          case ServiceCategory.towing:
          case ServiceCategory.medical:
            beaconColor = Colors.orangeAccent;
            break;
          default:
            beaconColor = Colors.tealAccent;
        }

        markers.add(
          Marker(
            point: LatLng(sLat, sLng),
            width: 50,
            height: 50,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                state.selectService(service);
                _mapController.move(LatLng(sLat, sLng), 15.5);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: beaconColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: beaconColor, width: 2),
                      ),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: beaconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        service.category == ServiceCategory.hospital ? 'H' : (service.category == ServiceCategory.police ? 'P' : '+'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Polyline routing to selected service
    final List<Polyline> polylines = [];
    if (state.selectedService != null && state.locationReady) {
      final sLat = state.userLat + state.selectedService!.mockLatOffset;
      final sLng = state.userLng + state.selectedService!.mockLngOffset;
      polylines.add(
        Polyline(
          points: [
            userLatLng,
            LatLng(sLat, sLng),
          ],
          color: theme.colorScheme.secondary,
          strokeWidth: 4,
          borderColor: theme.colorScheme.secondary.withOpacity(0.4),
          borderStrokeWidth: 6,
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: state.locationReady ? userLatLng : const LatLng(12.9716, 77.5946),
            initialZoom: 14.5,
            minZoom: 3,
            maxZoom: 18,
            interactionOptions: InteractionOptions(
              flags: widget.isStatic ? InteractiveFlag.none : InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.guardianpulse.guardian_pulse',
            ),
            if (polylines.isNotEmpty)
              PolylineLayer(
                polylines: polylines,
              ),
            MarkerLayer(
              markers: markers,
            ),
          ],
        ),

        // Monospace HUD Readout in Corner (Top-left HUD Overlay)
        Positioned(
          left: 12,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withOpacity(0.85) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              'SYS-TELEMETRY: ACTIVE\nLAT: ${state.userLat.toStringAsFixed(5)}° N\nLNG: ${state.userLng.toStringAsFixed(5)}° E\nRADAR: 3D-OSM-LIVE\nSAT-FIX: ONLINE',
              style: TextStyle(
                color: isDark ? const Color(0xFF2EC4B6) : Colors.black87,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                height: 1.4,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),

        // Zoom / Center Controls Overlay (Floating)
        if (!widget.isStatic)
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _buildMapButton(
                  icon: Icons.add,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      min(_mapController.camera.zoom + 1, 18),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.remove,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      max(_mapController.camera.zoom - 1, 3),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  onPressed: () {
                    if (state.locationReady) {
                      _mapController.move(userLatLng, 14.5);
                      state.selectService(null);
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMapButton({required IconData icon, required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
        onPressed: onPressed,
      ),
    );
  }
}
