import 'package:flutter/material.dart';

/// All supported device actions the model can trigger.
enum MobileActionType {
  flashlightOn,
  flashlightOff,
  createContact,
  sendEmail,
  showLocationOnMap,
  openWifiSettings,
  createCalendarEvent,
}

/// A recognised device action with its extracted parameters.
class MobileAction {
  final MobileActionType type;
  final Map<String, String> parameters;

  const MobileAction({required this.type, this.parameters = const {}});

  /// Human-readable label for the action.
  String get label {
    switch (type) {
      case MobileActionType.flashlightOn:
        return 'Turn On Flashlight';
      case MobileActionType.flashlightOff:
        return 'Turn Off Flashlight';
      case MobileActionType.createContact:
        return 'Create Contact';
      case MobileActionType.sendEmail:
        return 'Send Email';
      case MobileActionType.showLocationOnMap:
        return 'Show on Map';
      case MobileActionType.openWifiSettings:
        return 'Open WiFi Settings';
      case MobileActionType.createCalendarEvent:
        return 'Create Calendar Event';
    }
  }

  /// Material icon for the action.
  IconData get icon {
    switch (type) {
      case MobileActionType.flashlightOn:
        return Icons.flashlight_on_outlined;
      case MobileActionType.flashlightOff:
        return Icons.flashlight_off_outlined;
      case MobileActionType.createContact:
        return Icons.person_add_outlined;
      case MobileActionType.sendEmail:
        return Icons.email_outlined;
      case MobileActionType.showLocationOnMap:
        return Icons.map_outlined;
      case MobileActionType.openWifiSettings:
        return Icons.wifi;
      case MobileActionType.createCalendarEvent:
        return Icons.calendar_month_outlined;
    }
  }

  @override
  String toString() => 'MobileAction($type, $parameters)';
}

/// The result of executing a [MobileAction] on the device.
sealed class MobileActionResult {
  const MobileActionResult();
}

class ActionSuccess extends MobileActionResult {
  final String message;
  const ActionSuccess([this.message = 'Action completed successfully']);
}

class ActionFailure extends MobileActionResult {
  final String reason;
  const ActionFailure(this.reason);
}
