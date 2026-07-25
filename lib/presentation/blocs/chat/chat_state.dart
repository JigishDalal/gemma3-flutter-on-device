part of 'chat_bloc.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isGenerating;
  final bool isDownloading;
  final double downloadProgress;
  final bool isModelInstalled;
  final bool isModelInitialized;
  final bool isRecordingVoice;
  final bool isTranscribingVoice;
  final String? transcribedVoiceText;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isGenerating = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isModelInstalled = false,
    this.isModelInitialized = false,
    this.isRecordingVoice = false,
    this.isTranscribingVoice = false,
    this.transcribedVoiceText,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isGenerating,
    bool? isDownloading,
    double? downloadProgress,
    bool? isModelInstalled,
    bool? isModelInitialized,
    bool? isRecordingVoice,
    bool? isTranscribingVoice,
    String? transcribedVoiceText,
    bool clearTranscribedVoiceText = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isModelInstalled: isModelInstalled ?? this.isModelInstalled,
      isModelInitialized: isModelInitialized ?? this.isModelInitialized,
      isRecordingVoice: isRecordingVoice ?? this.isRecordingVoice,
      isTranscribingVoice: isTranscribingVoice ?? this.isTranscribingVoice,
      transcribedVoiceText: clearTranscribedVoiceText
          ? null
          : transcribedVoiceText ?? this.transcribedVoiceText,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isGenerating,
        isDownloading,
        downloadProgress,
        isModelInstalled,
        isModelInitialized,
        isRecordingVoice,
        isTranscribingVoice,
        transcribedVoiceText,
        errorMessage,
      ];
}
