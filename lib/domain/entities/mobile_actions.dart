/// Represents a Mobile Action tool from the Google AI Edge Mobile Actions dataset.
enum MobileActionType {
  turnOnFlashlight,
  turnOffFlashlight,
  createContact,
  sendEmail,
  showMapLocation,
  openWifiSettings,
  createCalendarEvent,
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
      case MobileActionType.turnOnFlashlight:
        return '🔦 Mobile Action Executed: Turned ON flashlight';

      case MobileActionType.turnOffFlashlight:
        return '🔦 Mobile Action Executed: Turned OFF flashlight';

      case MobileActionType.createContact:
        final name = arguments['name'] ?? arguments['contact_name'] ?? 'Contact';
        final phone = arguments['phone'] ?? arguments['phone_number'] ?? '';
        return '👤 Mobile Action Executed: Created contact "$name" ${phone.toString().isNotEmpty ? "($phone)" : ""}';

      case MobileActionType.sendEmail:
        final recipient = arguments['recipient'] ?? arguments['to'] ?? 'recipient';
        final subject = arguments['subject'] ?? 'No subject';
        return '✉️ Mobile Action Executed: Opened email composer for $recipient ($subject)';

      case MobileActionType.showMapLocation:
        final location = arguments['location'] ?? arguments['address'] ?? arguments['query'] ?? 'Location';
        return '📍 Mobile Action Executed: Opened maps for "$location"';

      case MobileActionType.openWifiSettings:
        return '📶 Mobile Action Executed: Opened WiFi Settings';

      case MobileActionType.createCalendarEvent:
        final title = arguments['title'] ?? arguments['event'] ?? 'Event';
        final dateTime = arguments['date_time'] ?? arguments['date'] ?? 'today';
        return '📅 Mobile Action Executed: Created calendar event "$title" on $dateTime';

      case MobileActionType.addExpense:
        final amount = arguments['amount'] ?? arguments['price'] ?? 0;
        final category = arguments['category'] ?? arguments['item'] ?? 'General';
        final currency = arguments['currency'] ?? '₹';
        return '💳 Mobile Action Executed: Saved expense of $currency$amount for $category';

      case MobileActionType.setTimer:
        final seconds = arguments['seconds'] ?? arguments['duration'] ?? 60;
        final label = arguments['label'] ?? 'Timer';
        return '⏱️ Mobile Action Executed: Set $label for $seconds seconds';

      case MobileActionType.openApp:
        final app = arguments['app_name'] ?? arguments['app'] ?? 'Settings';
        return '📱 Mobile Action Executed: Opened $app app';

      case MobileActionType.toggleSetting:
        final setting = arguments['setting_name'] ?? 'Setting';
        final enable = arguments['enable'] ?? true;
        return '⚡ Mobile Action Executed: Turned ${enable ? "ON" : "OFF"} $setting';

      case MobileActionType.unknown:
        return '⚡ Mobile Action Executed: $actionName';
    }
  }
}
