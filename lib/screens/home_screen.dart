import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/status_card.dart';
import '../widgets/sos_button.dart';
import '../widgets/emergency_banner.dart';
import '../widgets/guardian_card.dart';
import '../models/service.dart';

// Import all sub-screens to display them in tabs
import 'tracking_screen.dart';
import 'alerts_screen.dart';
import 'guardian_screen.dart';
import 'profile_screen.dart';
import 'nearby_services_screen.dart';
import 'emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation tabs list
  Widget _getBodyForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return const DashboardTab();
      case 1:
        return const TrackingScreen();
      case 2:
        return const AlertsScreen();
      case 3:
        // Reuse Guardian Screen content as a Tab View without individual appbars
        return const GuardianTabContent();
      case 4:
        return const ProfileScreen();
      default:
        return const DashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    // Auto-trigger Emergency screen overlay when SOS is active
    if (state.isEmergencyActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const EmergencyScreen()),
        );
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: state.currentTab == 0
            ? 'Guardian Pulse'
            : (state.currentTab == 1
                ? 'Live Tracking'
                : (state.currentTab == 2
                    ? 'Alert History'
                    : (state.currentTab == 3 ? 'My Guardians' : 'User Profile'))),
        showProfile: state.currentTab == 0,
      ),
      body: _getBodyForTab(state.currentTab),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

// Sub-widget: Dashboard Tab (Tab 0)
class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = Provider.of<AppState>(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated Safety Banner if GPS or SMS is off
          if (!state.locationPermission || !state.smsPermission)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Warning: Some permissions are disabled. Emergency detection might not work.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          
          // Safety Status Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatusCard(
              gpsActive: state.locationPermission,
              trackingActive: state.isTrackingActive,
              emergencyActive: state.isEmergencyActive,
            ),
          ),

          // Real-time Road Safety Telemetry Card (Open-Meteo Integration)
          if (state.locationReady) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [Colors.white, const Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: state.safetyScore > 80
                                  ? Colors.green
                                  : (state.safetyScore > 50 ? Colors.orange : Colors.red),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'LIVE SAFETY INDEX',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        // Live weather badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                state.rainMm > 0 ? Icons.cloudy_snowing : Icons.wb_sunny_rounded,
                                size: 12,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${state.currentTemp.toStringAsFixed(1)}°C • ${state.weatherDescription}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Safety score circle indicator
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: state.safetyScore / 100.0,
                                strokeWidth: 6,
                                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  state.safetyScore > 80
                                      ? Colors.green
                                      : (state.safetyScore > 50 ? Colors.orange : Colors.red),
                                ),
                              ),
                            ),
                            Text(
                              '${state.safetyScore.round()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Safety advices
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Road Advisory',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.safetyAdvice,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, thickness: 0.5, color: isDark ? Colors.white10 : Colors.black12),
                    const SizedBox(height: 10),
                    // Weather details list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEnvMetric(
                          icon: Icons.water_drop_rounded,
                          label: 'Precipitation',
                          value: '${state.rainMm} mm',
                          color: Colors.blue,
                        ),
                        _buildEnvMetric(
                          icon: Icons.air_rounded,
                          label: 'Wind Speed',
                          value: '${state.windSpeed} km/h',
                          color: Colors.teal,
                        ),
                        _buildEnvMetric(
                          icon: Icons.speed_rounded,
                          label: 'Current Speed',
                          value: '${state.mockSpeedKmh.toStringAsFixed(1)} km/h',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Main SOS Button Section
          const Center(
            child: Text(
              'IN CASE OF EMERGENCY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SOSButton(
            onTriggered: () {
              state.startSosCountdown(customMessage: 'Manual SOS triggered by user.');
            },
            isTriggered: state.isEmergencyActive,
          ),
          const SizedBox(height: 8),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Hold button for 2 seconds to alert guardians and medical services.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Quick Action Service Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick Assistance Services',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _buildQuickActionItem(
                  context,
                  icon: Icons.local_hospital_rounded,
                  label: 'Hospital',
                  color: Colors.red,
                  category: ServiceCategory.hospital,
                ),
                _buildQuickActionItem(
                  context,
                  icon: Icons.airport_shuttle_rounded,
                  label: 'Ambulance',
                  color: Colors.redAccent,
                  category: ServiceCategory.ambulance,
                ),
                _buildQuickActionItem(
                  context,
                  icon: Icons.local_police_rounded,
                  label: 'Police',
                  color: Colors.blue,
                  category: ServiceCategory.police,
                ),
                _buildQuickActionItem(
                  context,
                  icon: Icons.car_repair_rounded,
                  label: 'Towing',
                  color: Colors.orange,
                  category: ServiceCategory.towing,
                ),
                _buildQuickActionItem(
                  context,
                  icon: Icons.medical_services_rounded,
                  label: 'Medical',
                  color: Colors.orangeAccent,
                  category: ServiceCategory.medical,
                ),
                _buildQuickActionItem(
                  context,
                  icon: Icons.hotel_rounded,
                  label: 'Hotels',
                  color: Colors.teal,
                  category: ServiceCategory.hotel,
                ),
                _buildQuickActionItem(
                  context,
                  icon: Icons.restaurant_rounded,
                  label: 'Food',
                  color: Colors.tealAccent[700]!,
                  category: ServiceCategory.restaurant,
                ),
                _buildQuickActionItem(
                  context,
                  icon: Icons.map_rounded,
                  label: 'All Near',
                  color: Colors.blueGrey,
                  category: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Hackathon Simulation Control Center (Wow factor!)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      const Text(
                        'HACKATHON SIMULATOR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Simulate a sudden crash impact (Deceleration shock) to test the automated AI auto-SOS and countdown response trigger.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            state.simulateAccident();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Simulate Accident',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (state.isTrackingActive) {
                              state.stopTracking();
                            } else {
                              state.startTracking();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Simulated live GPS tracking active.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.isTrackingActive
                                ? Colors.amber.withOpacity(0.1)
                                : theme.colorScheme.secondary.withOpacity(0.1),
                            foregroundColor: state.isTrackingActive ? Colors.amber[800] : theme.colorScheme.secondary,
                            side: BorderSide(
                              color: state.isTrackingActive ? Colors.amber[800]! : theme.colorScheme.secondary,
                            ),
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            state.isTrackingActive ? 'Stop Tracking' : 'Start Tracking',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required ServiceCategory? category,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Set filter category and navigate to Nearby Services screen
        final state = Provider.of<AppState>(context, listen: false);
        state.filterServices(category);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NearbyServicesScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }
}

// Sub-widget: Guardian Tab Content
// Reuses guardian listing layout without scaffold wrapper
class GuardianTabContent extends StatelessWidget {
  const GuardianTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);

    // Render exact layout of Guardian Screen, but streamlined for tab view
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Contacts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: Icon(Icons.person_add_alt_rounded, color: theme.colorScheme.secondary),
                onPressed: () {
                  // Push the full add guardian setup screen for quick flow or show bottom sheet
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const GuardianScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.guardians.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No guardians linked yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: state.guardians.length,
                  itemBuilder: (context, index) {
                    final g = state.guardians[index];
                    return GuardianCard(
                      guardian: g,
                      onRemove: () {
                        state.removeGuardian(g.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
