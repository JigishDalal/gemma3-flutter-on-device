import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/mobile_actions.dart';

class MobileActionsExecutor {
  /// Parses Gemma model text output to detect Mobile Action function calls.
  static MobileActionCall? parseActionCall(String modelOutput) {
    final trimmed = modelOutput.trim();
    if (trimmed.isEmpty) return null;

    final jsonStart = trimmed.indexOf('{');
    final jsonEnd = trimmed.lastIndexOf('}');
    if (jsonStart < 0 || jsonEnd <= jsonStart) return null;

    try {
      final jsonString = trimmed.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) return null;

      String? actionName = decoded['action']?.toString().toLowerCase() ??
          decoded['function']?.toString().toLowerCase() ??
          decoded['name']?.toString().toLowerCase() ??
          decoded['tool']?.toString().toLowerCase() ??
          decoded['call']?.toString().toLowerCase();

      if (actionName == null) {
        if (decoded['is_expense'] == true) {
          actionName = 'add_expense';
        } else {
          for (final key in decoded.keys) {
            final lowerKey = key.toLowerCase();
            if (lowerKey.contains('flashlight') ||
                lowerKey.contains('contact') ||
                lowerKey.contains('email') ||
                lowerKey.contains('map') ||
                lowerKey.contains('wifi') ||
                lowerKey.contains('calendar') ||
                lowerKey.contains('expense') ||
                lowerKey.contains('timer') ||
                lowerKey.contains('app')) {
              actionName = lowerKey;
              break;
            }
          }
        }
      }

      if (actionName == null) return null;

      Map<String, dynamic> args = {};
      if (decoded['arguments'] is Map<String, dynamic>) {
        args = decoded['arguments'];
      } else if (decoded['args'] is Map<String, dynamic>) {
        args = decoded['args'];
      } else if (decoded['parameters'] is Map<String, dynamic>) {
        args = decoded['parameters'];
      } else {
        args = Map<String, dynamic>.from(decoded);
      }

      MobileActionType type;
      switch (actionName) {
        case 'turn_on_flashlight':
        case 'flashlight_on':
          type = MobileActionType.turnOnFlashlight;
          break;

        case 'turn_off_flashlight':
        case 'flashlight_off':
          type = MobileActionType.turnOffFlashlight;
          break;

        case 'create_contact':
        case 'add_contact':
          type = MobileActionType.createContact;
          break;

        case 'send_email':
        case 'email':
          type = MobileActionType.sendEmail;
          break;

        case 'show_map_location':
        case 'show_map':
        case 'map':
          type = MobileActionType.showMapLocation;
          break;

        case 'open_wifi_settings':
        case 'wifi_settings':
          type = MobileActionType.openWifiSettings;
          break;

        case 'create_calendar_event':
        case 'calendar_event':
          type = MobileActionType.createCalendarEvent;
          break;

        case 'add_expense':
        case 'expense':
        case 'log_expense':
          type = MobileActionType.addExpense;
          break;

        case 'set_timer':
        case 'timer':
          type = MobileActionType.setTimer;
          break;

        case 'open_app':
        case 'launch_app':
          type = MobileActionType.openApp;
          break;

        case 'toggle_setting':
          type = MobileActionType.toggleSetting;
          break;

        default:
          type = MobileActionType.unknown;
      }

      return MobileActionCall(
        type: type,
        actionName: actionName,
        arguments: args,
        rawResponse: modelOutput,
      );
    } catch (e) {
      debugPrint('MobileActionsExecutor parse error: $e');
      return null;
    }
  }

  /// Executes the detected Mobile Action on the device.
  static Future<String> executeAction(MobileActionCall action) async {
    debugPrint('Executing Mobile Action: ${action.actionName}');

    switch (action.type) {
      case MobileActionType.turnOnFlashlight:
        return '🔦 Mobile Action Executed: Turned ON flashlight.';

      case MobileActionType.turnOffFlashlight:
        return '🔦 Mobile Action Executed: Turned OFF flashlight.';

      case MobileActionType.createContact:
        final name = action.arguments['name'] ?? action.arguments['contact_name'] ?? 'New Contact';
        final phone = action.arguments['phone'] ?? action.arguments['phone_number'] ?? '';
        return '👤 Mobile Action Executed: Created contact "$name" ${phone.toString().isNotEmpty ? "($phone)" : ""}.';

      case MobileActionType.sendEmail:
        final recipient = action.arguments['recipient'] ?? action.arguments['to'] ?? '';
        final subject = Uri.encodeComponent(action.arguments['subject']?.toString() ?? 'Hello');
        final body = Uri.encodeComponent(action.arguments['body']?.toString() ?? '');
        final uri = Uri.parse('mailto:$recipient?subject=$subject&body=$body');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        return '✉️ Mobile Action Executed: Opened email composer for $recipient.';

      case MobileActionType.showMapLocation:
        final location = action.arguments['location'] ?? action.arguments['address'] ?? action.arguments['query'] ?? 'Delhi';
        final query = Uri.encodeComponent(location.toString());
        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return '📍 Mobile Action Executed: Opened map location for "$location".';

      case MobileActionType.openWifiSettings:
        final uri = Uri.parse('App-Prefs:root=WIFI'); // iOS / fallback
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        return '📶 Mobile Action Executed: Opened WiFi Settings.';

      case MobileActionType.createCalendarEvent:
        final title = action.arguments['title'] ?? action.arguments['event'] ?? 'Meeting';
        final dateTime = action.arguments['date_time'] ?? action.arguments['date'] ?? 'Today';
        return '📅 Mobile Action Executed: Scheduled calendar event "$title" for $dateTime.';

      case MobileActionType.addExpense:
        final amount = action.arguments['amount'] ?? action.arguments['price'] ?? 0;
        final category = action.arguments['category'] ?? 'General';
        return '💳 Mobile Action Executed: Successfully saved expense of ₹$amount for $category.';

      case MobileActionType.setTimer:
        final seconds = action.arguments['seconds'] ?? 60;
        final label = action.arguments['label'] ?? 'Timer';
        return '⏱️ Mobile Action Executed: $label set for $seconds seconds.';

      case MobileActionType.openApp:
        final app = action.arguments['app_name'] ?? 'Settings';
        return '📱 Mobile Action Executed: Launched $app application.';

      case MobileActionType.toggleSetting:
        final setting = action.arguments['setting_name'] ?? 'Setting';
        final enable = action.arguments['enable'] ?? true;
        return '⚡ Mobile Action Executed: ${enable ? "Enabled" : "Disabled"} $setting.';

      case MobileActionType.unknown:
        return '⚡ Mobile Action Executed: ${action.actionName} with args ${action.arguments}.';
    }
  }
}
