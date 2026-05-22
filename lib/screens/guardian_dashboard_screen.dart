import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/service.dart';
import '../widgets/map_widget.dart';
import 'login_screen.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({Key? key}) : super(key: key);

  @override
  State<GuardianDashboardScreen> createState() => _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  // Simulator triggers
  bool _commuterEmergencySimulated = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);

    // Mock closest hospital to user coordinates safely with a fallback
    final hospitals = state.services.where((s) => s.category == ServiceCategory.hospital).toList();
    final closestHospital = hospitals.isNotEmpty 
        ? hospitals.first 
        : NearbyService(
            id: 'default_h',
            name: 'Emergency Medical Hospital',
            category: ServiceCategory.hospital,
            distanceKm: 2.4,
            etaMinutes: 8,
            rating: 4.5,
            phone: '108',
            address: 'Nearby Emergency Centre, India',
            mockLatOffset: 0.01,
            mockLngOffset: 0.01,
          );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guardian Console',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Monitoring: Anbu Selvan (Commuter)',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, color: theme.colorScheme.secondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            onPressed: () {
              state.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live Commuter Map
          const MapWidget(showServices: false, isStatic: false),

          // Top Info Banner: Safety Status
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _commuterEmergencySimulated ? const Color(0xFF7F1D1D) : (isDark ? theme.colorScheme.surface : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _commuterEmergencySimulated ? Colors.redAccent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: _commuterEmergencySimulated ? 2 : 1,
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
                children: [
                  // Pulsing Status Dot
                  _StatusPulseDot(isCritical: _commuterEmergencySimulated),
                  const SizedBox(width: 12),
                  
                  // Status Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _commuterEmergencySimulated ? 'CRITICAL ALERT: CRASH DETECTED' : 'COMMUTER SAFETY STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _commuterEmergencySimulated ? Colors.white70 : Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _commuterEmergencySimulated
                              ? 'Impact reported near Richmond Rd'
                              : (state.isTrackingActive ? 'Active & Moving (45 km/h)' : 'Stationary / Safe'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _commuterEmergencySimulated ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions or times
                  Text(
                    _commuterEmergencySimulated ? 'Just Now' : 'Updated 1m ago',
                    style: TextStyle(
                      fontSize: 11,
                      color: _commuterEmergencySimulated ? Colors.white70 : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Closest Assistance Hospital Alert Card
                if (_commuterEmergencySimulated) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_hospital_rounded, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'NEAREST RESPONDER',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          closestHospital.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${closestHospital.address} • ETA: ${closestHospital.etaMinutes} mins (${closestHospital.distanceKm} km)',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action controls panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Calling Commuter (Anbu Selvan)...')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: BorderSide(color: theme.colorScheme.secondary),
                                foregroundColor: theme.colorScheme.secondary,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.call, size: 16),
                                  SizedBox(width: 8),
                                  Text('CALL USER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Starting GPS routing directions to coordinates: ${state.userLat.toStringAsFixed(6)}, ${state.userLng.toStringAsFixed(6)}'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.navigation_rounded, size: 16, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('NAVIGATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Emergency ambulance trigger
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dialing Emergency Ambulance (108)...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.airport_shuttle_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'CONTACT AMBULANCE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Simulator trigger floating on side for mock demonstration
          Positioned(
            right: 12,
            top: 80,
            child: FloatingActionButton.extended(
              heroTag: 'guardian_sim',
              onPressed: () {
                setState(() {
                  _commuterEmergencySimulated = !_commuterEmergencySimulated;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_commuterEmergencySimulated
                        ? 'Simulating Commuter Accident Shock Event'
                        : 'Resolved simulated emergency state.'),
                  ),
                );
              },
              backgroundColor: _commuterEmergencySimulated ? Colors.green : Colors.amber[800],
              foregroundColor: Colors.white,
              label: Text(_commuterEmergencySimulated ? 'RESOLVE' : 'SIMULATE CRASH'),
              icon: Icon(_commuterEmergencySimulated ? Icons.check_circle_rounded : Icons.warning_amber_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPulseDot extends StatefulWidget {
  final bool isCritical;

  const _StatusPulseDot({Key? key, required this.isCritical}) : super(key: key);

  @override
  State<_StatusPulseDot> createState() => _StatusPulseDotState();
}

class _StatusPulseDotState extends State<_StatusPulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isCritical ? Colors.red : Colors.green;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.3 + 0.7 * _controller.value),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4 * _controller.value),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
