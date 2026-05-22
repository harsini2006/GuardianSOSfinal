import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/emergency_alert.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfile;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showProfile = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);
    final profile = state.profile;

    return AppBar(
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      title: showProfile
          ? Row(
              children: [
                GestureDetector(
                  onTap: () {
                    state.setTab(4); // Navigate to Profile
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name.isNotEmpty ? 'Hello, ${profile.name}' : 'Guardian Pulse',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      state.userRole == 'guardian' ? 'Guardian Mode' : 'User Mode',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
      actions: [
        if (showProfile)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white : theme.colorScheme.primary,
                ),
                onPressed: () {
                  state.setTab(2); // Go to Alerts Timeline
                },
              ),
              if (state.alerts.any((a) => a.status == AlertStatus.active))
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
