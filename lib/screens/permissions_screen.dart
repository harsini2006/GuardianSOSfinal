import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);

    void _onContinue() {
      // Proceed to Home Dashboard
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (route) => false,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permissions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enable these permissions to ensure Guardian Pulse can run in the background and send alerts in real-time.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),

              // Permissions List
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionTile(
                      context,
                      icon: Icons.location_on_rounded,
                      title: 'Location Permission',
                      description: 'Provides live GPS coordinates to track driving speed, detect deceleration impact, and alert guardians.',
                      value: state.locationPermission,
                      onChanged: (_) => state.togglePermission('location'),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      context,
                      icon: Icons.sms_rounded,
                      title: 'SMS Permission',
                      description: 'Allows sending critical SMS location alerts to your linked guardians even if you lose internet connection.',
                      value: state.smsPermission,
                      onChanged: (_) => state.togglePermission('sms'),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      context,
                      icon: Icons.notifications_active_rounded,
                      title: 'Notification Permission',
                      description: 'Enables quick background status alerts and plays audible warning sounds when an emergency is detected.',
                      value: state.notificationPermission,
                      onChanged: (_) => state.togglePermission('notification'),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      context,
                      icon: Icons.mic_rounded,
                      title: 'Microphone Permission',
                      description: 'Enables voice response commands ("I\'m safe", "Help") during the emergency countdown without typing.',
                      value: state.microphonePermission,
                      onChanged: (_) => state.togglePermission('microphone'),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  CustomButton(
                    text: 'Enable All & Continue',
                    onPressed: () {
                      state.enableAllPermissions();
                      _onContinue();
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _onContinue,
                    child: const Text('Maybe Later', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? theme.colorScheme.secondary.withOpacity(0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? theme.colorScheme.secondary.withOpacity(0.12)
                  : theme.colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: value ? theme.colorScheme.secondary : theme.colorScheme.primary.withOpacity(0.4),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}
