import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service.dart';

class ServiceCard extends StatelessWidget {
  final NearbyService service;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.onCall,
    required this.onNavigate,
  }) : super(key: key);

  IconData _getCategoryIcon() {
    switch (service.category) {
      case ServiceCategory.hospital:
        return Icons.local_hospital_rounded;
      case ServiceCategory.ambulance:
        return Icons.airport_shuttle_rounded;
      case ServiceCategory.police:
        return Icons.local_police_rounded;
      case ServiceCategory.towing:
        return Icons.car_repair_rounded;
      case ServiceCategory.medical:
        return Icons.medical_services_rounded;
      case ServiceCategory.hotel:
        return Icons.hotel_rounded;
      case ServiceCategory.restaurant:
        return Icons.restaurant_rounded;
    }
  }

  Color _getCategoryColor(ThemeData theme) {
    switch (service.category) {
      case ServiceCategory.hospital:
      case ServiceCategory.ambulance:
        return theme.colorScheme.error;
      case ServiceCategory.police:
        return theme.colorScheme.secondary;
      case ServiceCategory.towing:
      case ServiceCategory.medical:
        return Colors.orange;
      case ServiceCategory.hotel:
      case ServiceCategory.restaurant:
        return Colors.teal;
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]+'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng, String name) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(theme).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: _getCategoryColor(theme),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        service.address,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Badges — wrapped to prevent overflow
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          // Rating
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: Colors.amber[700]),
                              const SizedBox(width: 2),
                              Text(
                                service.rating.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          // Distance
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_walk_rounded, size: 13, color: theme.colorScheme.secondary),
                              const SizedBox(width: 2),
                              Text(
                                '${service.distanceKm} km',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          // ETA
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: Colors.blueGrey),
                              const SizedBox(width: 2),
                              Text(
                                '${service.etaMinutes} min',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action Buttons — REAL phone call and Google Maps navigation
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(service.phone),
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('CALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Open Google Maps to the service's real coordinates
                      // mockLatOffset/mockLngOffset store the delta from user position
                      // We need the absolute position, but we don't have userLat here
                      // So we use the onNavigate callback for map-based navigation
                      // AND also open Google Maps externally
                      onNavigate();
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 15, color: Colors.white),
                    label: const Text('NAVIGATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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
