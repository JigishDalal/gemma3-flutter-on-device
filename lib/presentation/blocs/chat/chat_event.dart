part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class CheckModelStatusEvent extends ChatEvent {
  const CheckModelStatusEvent();
}

class SendMessageEvent extends ChatEvent {
  final String message;

  const SendMessageEvent({required this.message});

  @override
  List<Object> get props => [message];
}

class StartVoiceRecordingEvent extends ChatEvent {
  const StartVoiceRecordingEvent();
}

class StopVoiceRecordingEvent extends ChatEvent {
  const StopVoiceRecordingEvent();
}

class ClearTranscribedTextEvent extends ChatEvent {
  const ClearTranscribedTextEvent();
}
