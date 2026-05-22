import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../models/service.dart';
import '../widgets/service_card.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _voiceActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = Provider.of<AppState>(context);
    final isCountdownActive = state.emergencyCountdown > 0;

    // Handle exiting the screen if the emergency is resolved/canceled
    if (!state.isEmergencyActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF7F1D1D), // Dark blood red
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF991B1B).withOpacity(0.85 + 0.15 * _pulseController.value),
                    const Color(0xFF450A0A),
                  ],
                  radius: 1.2,
                ),
              ),
              child: child,
            );
          },
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Top Banner
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.report_gmailerrorred_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'GUARDIAN PULSE SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),

              // Body switcher: Countdown Timer OR Alert Sent Info
              if (isCountdownActive) ...[
                // Countdown Visual Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: state.emergencyCountdown / 10,
                        strokeWidth: 10,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Text(
                      '${state.emergencyCountdown}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Alert message details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        state.emergencyMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sending emergency SMS alerts with your live GPS location to your guardians automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Alert Sent State
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ALERTS SENT SUCCESSFULLY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Your ${state.guardians.length} guardians were alerted via SMS with coordinates: ${state.userLat.toStringAsFixed(5)}, ${state.userLng.toStringAsFixed(5)}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],

              const Spacer(),

              // Voice Response Command Indicator (Hackathon highlight!)
              if (isCountdownActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _voiceActive = !_voiceActive;
                      });
                      if (_voiceActive) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Listening for voice commands: "I\'m Safe" or "Help Now"'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _voiceActive ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _voiceActive ? Colors.white : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _voiceActive ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: _voiceActive ? Colors.greenAccent : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _voiceActive ? 'Listening... Speak "I\'M SAFE"' : 'Tap to Enable Voice Response',
                            style: TextStyle(
                              color: _voiceActive ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons panel
              if (isCountdownActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      // Need Help immediately button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                state.triggerImmediateSos();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF7F1D1D),
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'SEND NOW',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Ambulance Call button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                launchUrl(Uri.parse('tel:108'));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[800],
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'AMBULANCE',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Giant "I'M SAFE" Cancel Button (easy to tap)
                      ElevatedButton(
                        onPressed: () {
                          state.cancelSos();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'I’M SAFE (CANCEL)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.0),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // After alert sent: display emergency service suggestions
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'NEARBY EMERGENCY SERVICES',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Horizontal list of nearest services
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.services.where((s) => s.category == ServiceCategory.hospital || s.category == ServiceCategory.ambulance || s.category == ServiceCategory.police).length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final service = state.services.where((s) => s.category == ServiceCategory.hospital || s.category == ServiceCategory.ambulance || s.category == ServiceCategory.police).toList()[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Theme(
                          data: ThemeData.dark(),
                          child: ServiceCard(
                            service: service,
                            onCall: () {
                              final cleaned = service.phone.replaceAll(RegExp(r'[\s\-()]+'), '');
                              launchUrl(Uri.parse('tel:$cleaned'));
                            },
                            onNavigate: () {
                              final sLat = state.userLat + service.mockLatOffset;
                              final sLng = state.userLng + service.mockLngOffset;
                              launchUrl(
                                Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$sLat,$sLng'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const Spacer(),
                
                // Back to dashboard
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () {
                      state.resolveEmergency();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'RESOLVE & RETURN TO HOME',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
