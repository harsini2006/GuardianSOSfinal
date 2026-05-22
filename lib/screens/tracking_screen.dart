import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../widgets/map_widget.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);

    return Stack(
      children: [
        // Live Vector Map
        const MapWidget(showServices: true, isStatic: false),

        // Top Status Overlay (Speed and Accuracy)
        Positioned(
          left: 16,
          right: 72, // keep room for map zoom buttons on right
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Speed Indicator
                Row(
                  children: [
                    Icon(Icons.speed_rounded, color: theme.colorScheme.secondary, size: 24),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'SPEED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          state.isTrackingActive
                              ? '${state.mockSpeedKmh.toStringAsFixed(0)} km/h'
                              : '0 km/h',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Vertical Divider
                Container(width: 1, height: 30, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                // GPS Accuracy Indicator
                Row(
                  children: [
                    Icon(
                      state.isTrackingActive ? Icons.radar_rounded : Icons.radar_outlined,
                      color: state.isTrackingActive ? const Color(0xFF059669) : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GPS ACCURACY',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Text(
                          state.isTrackingActive
                              ? '± ${state.gpsAccuracyMeter.toStringAsFixed(1)} m'
                              : 'Offline',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom Banner Overlay (Location Sharing Active Indicator)
        if (state.isTrackingActive)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Live tracking and guardian sharing active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.share_location_rounded, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),

        // Floating Action Buttons (SOS, Share, Stop/Start Tracking)
        Positioned(
          right: 12,
          bottom: state.isTrackingActive ? 80 : 20, // push up slightly if bottom banner is active
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SOS Floating Button (Urgent Red)
              FloatingActionButton(
                heroTag: 'tracking_sos',
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                onPressed: () {
                  state.startSosCountdown(customMessage: 'SOS activated from Tracking Screen.');
                },
                child: const Icon(Icons.warning_amber_rounded, size: 28),
              ),
              const SizedBox(height: 12),

              // Share Location Button
              FloatingActionButton(
                heroTag: 'tracking_share',
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                foregroundColor: theme.colorScheme.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                onPressed: () {
                  // Share live location via Google Maps link to all guardians via SMS
                  final link = 'https://maps.google.com/?q=${state.userLat},${state.userLng}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Live location shared: ${state.userLat.toStringAsFixed(5)}, ${state.userLng.toStringAsFixed(5)}'),
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'OPEN MAP',
                        onPressed: () {
                          launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
                        },
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.share_rounded),
              ),
              const SizedBox(height: 12),

              // Stop/Start Tracking Button
              FloatingActionButton(
                heroTag: 'tracking_stop',
                backgroundColor: state.isTrackingActive ? const Color(0xFF334155) : theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                onPressed: () {
                  if (state.isTrackingActive) {
                    state.stopTracking();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GPS tracking paused.')),
                    );
                  } else {
                    state.startTracking();
                  }
                },
                child: Icon(state.isTrackingActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
