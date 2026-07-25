import 'dart:convert';

import '../../domain/entities/mobile_action.dart';

/// Result of parsing model output — either a function call or plain text.
sealed class ParsedModelOutput {
  const ParsedModelOutput();
}

/// The model chose to call a device function.
class ParsedFunctionCall extends ParsedModelOutput {
  final MobileAction action;
  const ParsedFunctionCall(this.action);
}

/// The model responded with normal text (no function call detected).
class ParsedTextResponse extends ParsedModelOutput {
  final String text;
  const ParsedTextResponse(this.text);
}

/// Parses the raw model output and decides whether it contains a function call
/// or a normal text response.
abstract final class FunctionCallParser {
  /// Tries to extract a function call from [rawOutput].
  /// Falls back to [ParsedTextResponse] if no valid function call is found.
  static ParsedModelOutput parse(String rawOutput) {
    final trimmed = rawOutput.trim();

    // Strip markdown code fences if present
    final cleaned = _stripCodeFences(trimmed);

    // Try to find a JSON object with "function_call"
    final jsonStr = _extractJson(cleaned);
    if (jsonStr == null) return ParsedTextResponse(trimmed);

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return ParsedTextResponse(trimmed);

      // Check for {"function_call": {"name": "...", "arguments": {...}}}
      final functionCall = decoded['function_call'];
      if (functionCall is! Map<String, dynamic>) {
        return ParsedTextResponse(trimmed);
      }

      final name = functionCall['name'] as String?;
      if (name == null) return ParsedTextResponse(trimmed);

      final actionType = _mapNameToType(name);
      if (actionType == null) return ParsedTextResponse(trimmed);

      // Extract arguments as Map<String, String>
      final rawArgs = functionCall['arguments'];
      final args = <String, String>{};
      if (rawArgs is Map) {
        for (final entry in rawArgs.entries) {
          args[entry.key.toString()] = entry.value.toString();
        }
      }

      return ParsedFunctionCall(
        MobileAction(type: actionType, parameters: args),
      );
    } catch (_) {
      return ParsedTextResponse(trimmed);
    }
  }

  /// Maps function name strings to [MobileActionType] enums.
  static MobileActionType? _mapNameToType(String name) {
    // Normalise: lowercase + strip underscores
    final normalised = name.toLowerCase().replaceAll('_', '');
    return switch (normalised) {
      'turnonflashlight' => MobileActionType.flashlightOn,
      'turnoffflashlight' => MobileActionType.flashlightOff,
      'createcontact' => MobileActionType.createContact,
      'sendemail' => MobileActionType.sendEmail,
      'showlocationonmap' => MobileActionType.showLocationOnMap,
      'openwifisettings' => MobileActionType.openWifiSettings,
      'createcalendarevent' => MobileActionType.createCalendarEvent,
      // Also handle snake_case variants
      _ => _fuzzyMatch(normalised),
    };
  }

  /// Handles slight naming variations the model might produce.
  static MobileActionType? _fuzzyMatch(String n) {
    if (n.contains('flashlight') && n.contains('on')) {
      return MobileActionType.flashlightOn;
    }
    if (n.contains('flashlight') && n.contains('off')) {
      return MobileActionType.flashlightOff;
    }
    if (n.contains('contact')) return MobileActionType.createContact;
    if (n.contains('email') || n.contains('mail')) {
      return MobileActionType.sendEmail;
    }
    if (n.contains('map') || n.contains('location')) {
      return MobileActionType.showLocationOnMap;
    }
    if (n.contains('wifi')) return MobileActionType.openWifiSettings;
    if (n.contains('calendar') || n.contains('event')) {
      return MobileActionType.createCalendarEvent;
    }
    return null;
  }

  /// Strips ```json ... ``` markdown fences.
  static String _stripCodeFences(String input) {
    final fencePattern = RegExp(r'```(?:json)?\s*\n?(.*?)\n?\s*```', dotAll: true);
    final match = fencePattern.firstMatch(input);
    return match != null ? match.group(1)!.trim() : input;
  }

  /// Extracts the first top-level JSON object from the string.
  static String? _extractJson(String input) {
    final start = input.indexOf('{');
    if (start == -1) return null;

    var depth = 0;
    for (var i = start; i < input.length; i++) {
      if (input[i] == '{') depth++;
      if (input[i] == '}') depth--;
      if (depth == 0) {
        return input.substring(start, i + 1);
      }
    }
    return null;
  }
}
