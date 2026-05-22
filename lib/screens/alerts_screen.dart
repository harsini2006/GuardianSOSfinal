import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/emergency_alert.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  Color _getStatusColor(AlertStatus status, ThemeData theme) {
    return status == AlertStatus.active ? theme.colorScheme.error : theme.colorScheme.secondary;
  }

  IconData _getIconForType(AlertType type) {
    switch (type) {
      case AlertType.sos:
        return Icons.notifications_active_rounded;
      case AlertType.accident:
        return Icons.car_crash_rounded;
      case AlertType.manual:
        return Icons.report_problem_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Screen Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Safety & Alert Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Logs of all safety events, shock impacts, and emergency triggers on this device.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Timeline logs list
        Expanded(
          child: state.alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 64,
                        color: theme.colorScheme.secondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All Clear! No alerts triggered.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: state.alerts.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final alert = state.alerts[index];
                    final isLast = index == state.alerts.length - 1;
                    final isAlertActive = alert.status == AlertStatus.active;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Timeline line & indicator
                          Column(
                            children: [
                              // Node indicator dot
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isAlertActive
                                      ? theme.colorScheme.error.withOpacity(0.12)
                                      : theme.colorScheme.secondary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isAlertActive ? theme.colorScheme.error : theme.colorScheme.secondary,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _getIconForType(alert.type),
                                  color: isAlertActive ? theme.colorScheme.error : theme.colorScheme.secondary,
                                  size: 18,
                                ),
                              ),
                              // Vertical connecting line
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                )
                              else
                                const SizedBox(height: 20),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // Event Log Card
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? theme.colorScheme.surface : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isAlertActive
                                        ? theme.colorScheme.error.withOpacity(0.5)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Expanded(
                                          child: Text(
                                            alert.title,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Status Tag
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(alert.status, theme).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            alert.status == AlertStatus.active ? 'ACTIVE' : 'RESOLVED',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(alert.status, theme),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // Timestamp
                                    Text(
                                      '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')} • ${alert.timestamp.day}/${alert.timestamp.month}/${alert.timestamp.year}',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),

                                    // Description
                                    Text(
                                      alert.description,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
