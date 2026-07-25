/// Centralized application text constants.
class AppStrings {
  const AppStrings._();

  // App & Header
  static const String appTitle = 'Gemma 3';
  static const String appSubtitle = '· On Device';

  // Model Status Tooltips
  static const String statusModelReady = 'Model ready';
  static const String statusModelInstalled = 'Model installed';
  static const String statusModelNotInstalled = 'Model not installed';

  // Input & Messaging
  static const String inputHintText = 'Type something…';
  static const String emptyModelResponse = '(Empty response from model)';
  static const String modelThinking = 'Gemma is thinking…';

  // Download Card
  static const String downloadingTitle = 'Downloading Gemma 3';
  static const String downloadingSubtitle = 'On-device AI model · ~150 MB';

  // Voice & Recording Overlay
  static const String labelListening = 'LISTENING';
  static const String labelTranscribing = 'TRANSCRIBING WITH WHISPER';
  static const String subtitleListening = 'Speak now, tap Stop when done';
  static const String subtitleTranscribing = 'Processing your voice…';
  static const String buttonStopRecording = 'Stop Recording';

  // Expense Formatting & Banners
  static const String headerModelOutput = '🤖 Model Output:';
  static const String headerCompleteExpense = '✅ Expense Detected Successfully';
  static const String headerIncompleteExpense = '⚠️ Incomplete Expense Details';
  static const String headerNoExpense = 'ℹ️ No Expense Detected';

  static const String labelAmount = '💵 Amount:';
  static const String labelCategory = '🏷️ Category:';
  static const String labelMerchant = '🏪 Merchant:';
  static const String labelDate = '📅 Date:';
  static const String labelDescription = '📝 Description:';
  static const String labelStatus = 'Status:';
  static const String labelReason = 'Reason:';

  static const String statusComplete = 'Complete';
  static const String statusIncomplete = 'Incomplete';
  static const String statusNotAnExpense = 'Not an Expense';
  static const String currencyDefault = 'N/A';
  static const String categoryGeneral = 'General';
}
