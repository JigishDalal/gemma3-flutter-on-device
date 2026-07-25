import 'package:intl/intl.dart';

/// Builds a Gemma system prompt that includes tool definitions so the model
/// can perform function calling via structured JSON output.
abstract final class FunctionCallPrompt {
  /// Creates the full prompt with tool definitions + user input.
  static String build(String userInput, {DateTime? now}) {
    final dt = now ?? DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy – HH:mm').format(dt);

    return '''
<start_of_turn>system
You are a helpful AI assistant running on a mobile phone. The current date and time is $dateStr.

You have access to the following tools (functions) that control the device:

$_toolDefinitions

INSTRUCTIONS:
- If the user's request matches one of the available tools, respond with ONLY a JSON object in this exact format:
  {"function_call": {"name": "<function_name>", "arguments": {<key-value pairs>}}}
- If the user's request does NOT match any tool, respond normally with helpful text.
- Do NOT wrap JSON in markdown code fences.
- Do NOT add any text before or after the JSON when calling a function.
- Arguments must be strings.
<end_of_turn>
<start_of_turn>user
$userInput
<end_of_turn>
<start_of_turn>model
''';
  }

  static const String _toolDefinitions = '''
1. turnOnFlashlight
   Description: Turns the flashlight on
   Parameters: none

2. turnOffFlashlight
   Description: Turns the flashlight off
   Parameters: none

3. createContact
   Description: Creates a contact in the phone's contact list
   Parameters:
     - name (string, required): The contact's full name
     - phone (string, optional): The phone number
     - email (string, optional): The email address

4. sendEmail
   Description: Sends an email
   Parameters:
     - to (string, required): The recipient email address
     - subject (string, required): The email subject
     - body (string, optional): The email body text

5. showLocationOnMap
   Description: Shows a location on the map
   Parameters:
     - location (string, required): The place name or address to show

6. openWifiSettings
   Description: Opens the WiFi settings screen
   Parameters: none

7. createCalendarEvent
   Description: Creates a new calendar event
   Parameters:
     - title (string, required): The event title
     - start_time (string, optional): Start time in ISO 8601 format
     - end_time (string, optional): End time in ISO 8601 format''';
}
