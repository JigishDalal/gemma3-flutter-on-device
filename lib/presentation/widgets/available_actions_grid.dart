import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AvailableActionItem {
  final String label;
  final IconData icon;
  final String prompt;

  const AvailableActionItem({
    required this.label,
    required this.icon,
    required this.prompt,
  });
}

class AvailableActionsGrid extends StatelessWidget {
  final ValueChanged<String> onActionSelected;

  const AvailableActionsGrid({
    super.key,
    required this.onActionSelected,
  });

  static const _actions = [
    AvailableActionItem(
      label: 'Flashlight',
      icon: Icons.flashlight_on_outlined,
      prompt: 'Turn on the flashlight',
    ),
    AvailableActionItem(
      label: 'Email',
      icon: Icons.email_outlined,
      prompt: 'Send an email to john@example.com about the project update',
    ),
    AvailableActionItem(
      label: 'Maps',
      icon: Icons.map_outlined,
      prompt: 'Show me Central Park, New York on the map',
    ),
    AvailableActionItem(
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      prompt: 'Create a calendar event for Team Sync tomorrow at 10 AM',
    ),
    AvailableActionItem(
      label: 'Contacts',
      icon: Icons.person_add_outlined,
      prompt: 'Add John Doe (555-0123) to my contacts',
    ),
    AvailableActionItem(
      label: 'WiFi',
      icon: Icons.wifi,
      prompt: 'Open WiFi settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(action.label),
                  avatar: Icon(
                    action.icon,
                    size: 18,
                    color: AppTheme.accentGradientB,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: () => onActionSelected(action.prompt),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
