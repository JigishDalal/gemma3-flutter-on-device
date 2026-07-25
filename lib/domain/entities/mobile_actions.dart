/// Represents a Mobile Action triggered by Gemma AI on the device.
enum MobileActionType {
  addExpense,
  setTimer,
  openApp,
  toggleSetting,
  unknown,
}

class MobileActionCall {
  final MobileActionType type;
  final String actionName;
  final Map<String, dynamic> arguments;
  final String rawResponse;

  const MobileActionCall({
    required this.type,
    required this.actionName,
    required this.arguments,
    required this.rawResponse,
  });

  /// Formats execution status for UI display.
  String get displaySummary {
    switch (type) {
      case MobileActionType.addExpense:
        final amount = arguments['amount'] ?? arguments['price'] ?? 0;
        final category = arguments['category'] ?? arguments['item'] ?? 'General';
        final currency = arguments['currency'] ?? '₹';
        return '💳 Action Executed: Recorded expense of $currency$amount for $category';

      case MobileActionType.setTimer:
        final seconds = arguments['seconds'] ?? arguments['duration'] ?? 60;
        final label = arguments['label'] ?? arguments['name'] ?? 'Timer';
        return '⏱️ Action Executed: Set $label for $seconds seconds';

      case MobileActionType.openApp:
        final app = arguments['app_name'] ?? arguments['app'] ?? 'Settings';
        return '📱 Action Executed: Opened $app app';

      case MobileActionType.toggleSetting:
        final setting = arguments['setting_name'] ?? arguments['setting'] ?? 'Feature';
        final enable = arguments['enable'] ?? true;
        return '⚡ Action Executed: Turned ${enable ? "ON" : "OFF"} $setting';

      case MobileActionType.unknown:
        return '⚡ Action Executed: $actionName';
    }
  }
}
