import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/repositories/model_repository.dart';
import '../../../data/services/mobile_actions_executor.dart';
import '../../../data/services/voice_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ModelRepository repository;
  final VoiceService voiceService = VoiceService();
  final _uuid = const Uuid();

  ChatBloc({required this.repository}) : super(const ChatState()) {
    on<CheckModelStatusEvent>(_onCheckModelStatus);
    on<DownloadModelEvent>(_onDownloadModel);
    on<SendMessageEvent>(_onSendMessage);
    on<StartVoiceRecordingEvent>(_onStartVoiceRecording);
    on<StopVoiceRecordingEvent>(_onStopVoiceRecording);
    on<ClearTranscribedTextEvent>(_onClearTranscribedText);
    add(const CheckModelStatusEvent());
  }

  Future<void> _onCheckModelStatus(
    CheckModelStatusEvent event,
    Emitter<ChatState> emit,
  ) async {
    final isInstalled = await repository.isModelInstalled();
    final isInitialized = repository.isModelInitialized;
    emit(
      state.copyWith(
        isModelInstalled: isInstalled,
        isModelInitialized: isInitialized,
      ),
    );

    if (isInstalled && !isInitialized) {
      try {
        await repository.initializeModel();
        emit(
          state.copyWith(
            isModelInstalled: true,
            isModelInitialized: repository.isModelInitialized,
          ),
        );
      } catch (e) {
        debugPrint('Failed auto-initializing model: $e');
      }
    }
  }

  Future<void> _onDownloadModel(
    DownloadModelEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isDownloading || state.isModelInstalled) return;
    emit(state.copyWith(isDownloading: true, downloadProgress: 0.0, clearError: true));

    try {
      await for (final chunk
          in repository.generateExpenseResponseStream('')) {
        if (chunk.startsWith('<download>') && chunk.endsWith('</download>')) {
          final pct =
              int.tryParse(
                chunk
                    .replaceAll('<download>', '')
                    .replaceAll('</download>', ''),
              ) ??
              0;
          emit(state.copyWith(
            isDownloading: true,
            downloadProgress: pct / 100,
          ));
        } else if (chunk.startsWith('<error>') && chunk.endsWith('</error>')) {
          emit(state.copyWith(
            errorMessage: chunk
                .replaceAll('<error>', '')
                .replaceAll('</error>', ''),
          ));
          return;
        } else {
          // model is loaded — download complete
          break;
        }
      }

      try {
        await repository.initializeModel();
      } catch (_) {}

      emit(state.copyWith(
        isDownloading: false,
        isModelInstalled: true,
        isModelInitialized: repository.isModelInitialized,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDownloading: false,
        errorMessage: 'Download failed: $e',
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: event.message,
      isUser: true,
    );

    emit(
      state.copyWith(
        messages: List.of(state.messages)..add(userMessage),
        isGenerating: true,
        clearError: true,
      ),
    );

    final response = StringBuffer();
    try {
      await for (final chunk in repository.generateExpenseResponseStream(
        event.message,
      )) {
        if (chunk.startsWith('<download>') && chunk.endsWith('</download>')) {
          final percentage =
              int.tryParse(
                chunk
                    .replaceAll('<download>', '')
                    .replaceAll('</download>', ''),
              ) ??
              0;
          emit(
            state.copyWith(
              isDownloading: true,
              isModelInstalled: false,
              downloadProgress: percentage / 100,
            ),
          );
        } else if (chunk.startsWith('<error>') && chunk.endsWith('</error>')) {
          emit(
            state.copyWith(
              errorMessage: chunk
                  .replaceAll('<error>', '')
                  .replaceAll('</error>', ''),
            ),
          );
        } else {
          response.write(chunk);
        }
      }

      final rawOutput = response.toString();
      debugPrint('Gemma direct raw output: $rawOutput');

      String messageText =
          rawOutput.isEmpty ? '(Empty response from model)' : rawOutput;

      final actionCall = MobileActionsExecutor.parseActionCall(rawOutput);
      if (actionCall != null) {
        final executionResult =
            await MobileActionsExecutor.executeAction(actionCall);
        messageText = executionResult;
      }

      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        text: messageText,
        isUser: false,
      );

      emit(
        state.copyWith(
          messages: List.of(state.messages)..add(assistantMessage),
          isModelInstalled: true,
          isModelInitialized: repository.isModelInitialized,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Error during model generation: $e'));
    } finally {
      emit(
        state.copyWith(
          isGenerating: false,
          isDownloading: false,
          isModelInitialized: repository.isModelInitialized,
        ),
      );
    }
  }

  Future<void> _onStartVoiceRecording(
    StartVoiceRecordingEvent event,
    Emitter<ChatState> emit,
  ) async {
    final hasPerm = await voiceService.hasPermission();
    if (!hasPerm) {
      emit(state.copyWith(errorMessage: 'Microphone permission denied.'));
      return;
    }

    try {
      await voiceService.startRecording();
      emit(state.copyWith(isRecordingVoice: true, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to start recording: $e'));
    }
  }

  Future<void> _onStopVoiceRecording(
    StopVoiceRecordingEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isRecordingVoice: false, isTranscribingVoice: true));
    try {
      final text = await voiceService.stopRecordingAndTranscribe();
      if (text != null && text.isNotEmpty) {
        emit(
          state.copyWith(
            isTranscribingVoice: false,
            transcribedVoiceText: text,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isTranscribingVoice: false,
            errorMessage:
                'Could not transcribe speech. Please try speaking clearly.',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isTranscribingVoice: false,
          errorMessage: 'Whisper transcription failed: $e',
        ),
      );
    }
  }

  Future<void> _onClearTranscribedText(
    ClearTranscribedTextEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(clearTranscribedVoiceText: true));
  }

  @override
  Future<void> close() {
    voiceService.dispose();
    return super.close();
  }
}
