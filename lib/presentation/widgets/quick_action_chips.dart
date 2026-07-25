import 'package:flutter/material.dart';

/// Horizontally scrollable quick action chips for triggering official Mobile Actions tools directly.
class QuickActionChips extends StatelessWidget {
  final ValueChanged<String> onActionSelected;

  const QuickActionChips({
    super.key,
    required this.onActionSelected,
  });

  static const List<_QuickActionItem> _actions = [
    _QuickActionItem(
      label: '🔦 Flashlight ON',
      prompt: 'Turn on the flashlight',
    ),
    _QuickActionItem(
      label: '👤 Create Contact',
      prompt: 'Create a contact for Alex with phone 9876543210',
    ),
    _QuickActionItem(
      label: '✉️ Send Email',
      prompt: 'Send an email to team@company.com with subject Weekly Status',
    ),
    _QuickActionItem(
      label: '📍 Map Location',
      prompt: 'Show Taj Mahal on the map',
    ),
    _QuickActionItem(
      label: '📶 WiFi Settings',
      prompt: 'Open the WiFi settings',
    ),
    _QuickActionItem(
      label: '📅 Calendar Event',
      prompt: 'Create a calendar event Team Sync at 10:00 AM',
    ),
    _QuickActionItem(
      label: '💳 Add Expense',
      prompt: 'Paid ₹500 for groceries',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _actions[index];
          return ActionChip(
            elevation: 0,
            pressElevation: 1,
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            label: Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            onPressed: () => onActionSelected(item.prompt),
          );
        },
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final String prompt;

  const _QuickActionItem({
    required this.label,
    required this.prompt,
  });
}
