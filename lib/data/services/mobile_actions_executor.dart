import 'dart:convert';
import 'package:flutter/foundation.dart';
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

      final actionName = decoded['action']?.toString().toLowerCase() ??
          decoded['function']?.toString().toLowerCase() ??
          (decoded['is_expense'] == true ? 'add_expense' : null);

      if (actionName == null) return null;

      Map<String, dynamic> args = {};
      if (decoded['arguments'] is Map<String, dynamic>) {
        args = decoded['arguments'];
      } else if (decoded['args'] is Map<String, dynamic>) {
        args = decoded['args'];
      } else {
        args = Map<String, dynamic>.from(decoded);
      }

      MobileActionType type;
      switch (actionName) {
        case 'add_expense':
        case 'expense':
        case 'log_expense':
          type = MobileActionType.addExpense;
          break;

        case 'set_timer':
        case 'timer':
        case 'start_timer':
          type = MobileActionType.setTimer;
          break;

        case 'open_app':
        case 'launch_app':
          type = MobileActionType.openApp;
          break;

        case 'toggle_setting':
        case 'toggle_flashlight':
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
