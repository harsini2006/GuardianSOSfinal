import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final bool gpsActive;
  final bool trackingActive;
  final bool emergencyActive;

  const StatusCard({
    Key? key,
    required this.gpsActive,
    required this.trackingActive,
    required this.emergencyActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emergencyActive
              ? theme.colorScheme.error.withOpacity(0.3)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: emergencyActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // GPS Status
          _buildStatusItem(
            context,
            icon: gpsActive ? Icons.gps_fixed : Icons.gps_off,
            label: 'GPS',
            statusText: gpsActive ? 'ACTIVE' : 'OFF',
            statusColor: gpsActive ? theme.colorScheme.secondary : const Color(0xFF64748B),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 40,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),

          // Tracking Status
          _buildStatusItem(
            context,
            icon: Icons.radar_rounded,
            label: 'TRACKING',
            statusText: trackingActive ? 'ON' : 'OFF',
            statusColor: trackingActive ? const Color(0xFF059669) : const Color(0xFF64748B),
            isPulse: trackingActive,
          ),

          // Divider
          Container(
            width: 1,
            height: 40,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),

          // Safety Status
          _buildStatusItem(
            context,
            icon: emergencyActive ? Icons.gpp_maybe_rounded : Icons.verified_user_rounded,
            label: 'STATUS',
            statusText: emergencyActive ? 'ALERT' : 'SAFE',
            statusColor: emergencyActive ? theme.colorScheme.error : const Color(0xFF059669),
            isPulse: emergencyActive,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String statusText,
    required Color statusColor,
    bool isPulse = false,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPulse)
              _BlinkingDot(color: statusColor)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(0.5),
                ),
              ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 18,
              color: theme.brightness == Brightness.dark ? Colors.white70 : theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          statusText,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  final Color color;

  const _BlinkingDot({Key? key, required this.color}) : super(key: key);

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.2 + 0.8 * _controller.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * _controller.value),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
