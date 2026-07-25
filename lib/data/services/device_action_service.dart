import 'package:flutter/services.dart';

import '../../domain/entities/mobile_action.dart';

/// Executes device actions via Android platform channel.
///
/// Each method sends a message to the native `DeviceActionHandler`
/// registered in `MainActivity.kt`.
class DeviceActionService {
  static const _channel = MethodChannel('com.ailocalmodel/device_actions');

  /// Executes a [MobileAction] and returns the result.
  Future<MobileActionResult> execute(MobileAction action) async {
    try {
      switch (action.type) {
        case MobileActionType.flashlightOn:
          await _channel.invokeMethod('toggleFlashlight', {'enabled': true});
          return const ActionSuccess('Flashlight turned on');

        case MobileActionType.flashlightOff:
          await _channel.invokeMethod('toggleFlashlight', {'enabled': false});
          return const ActionSuccess('Flashlight turned off');

        case MobileActionType.createContact:
          await _channel.invokeMethod('createContact', {
            'name': action.parameters['name'] ?? '',
            'phone': action.parameters['phone'] ?? '',
            'email': action.parameters['email'] ?? '',
          });
          return ActionSuccess(
            'Opening contacts to add ${action.parameters['name'] ?? 'contact'}',
          );

        case MobileActionType.sendEmail:
          await _channel.invokeMethod('sendEmail', {
            'to': action.parameters['to'] ?? '',
            'subject': action.parameters['subject'] ?? '',
            'body': action.parameters['body'] ?? '',
          });
          return ActionSuccess(
            'Opening email to ${action.parameters['to'] ?? 'recipient'}',
          );

        case MobileActionType.showLocationOnMap:
          await _channel.invokeMethod('showLocationOnMap', {
            'location': action.parameters['location'] ?? '',
          });
          return ActionSuccess(
            'Opening map for ${action.parameters['location'] ?? 'location'}',
          );

        case MobileActionType.openWifiSettings:
          await _channel.invokeMethod('openWifiSettings');
          return const ActionSuccess('Opening WiFi settings');

        case MobileActionType.createCalendarEvent:
          await _channel.invokeMethod('createCalendarEvent', {
            'title': action.parameters['title'] ?? '',
            'start_time': action.parameters['start_time'] ?? '',
            'end_time': action.parameters['end_time'] ?? '',
          });
          return ActionSuccess(
            'Creating calendar event: ${action.parameters['title'] ?? 'event'}',
          );
      }
    } on PlatformException catch (e) {
      return ActionFailure('Platform error: ${e.message}');
    } on MissingPluginException {
      return const ActionFailure(
        'Device actions are not available on this platform',
      );
    } catch (e) {
      return ActionFailure('Failed to execute action: $e');
    }
  }
}
