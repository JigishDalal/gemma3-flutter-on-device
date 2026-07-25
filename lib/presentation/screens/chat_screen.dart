import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/chat/chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatBloc>().add(SendMessageEvent(message: message));
      _controller.clear();
    }
  }

  void _toggleVoiceRecording(ChatState state) {
    final bloc = context.read<ChatBloc>();
    if (state.isRecordingVoice) {
      bloc.add(const StopVoiceRecordingEvent());
    } else {
      bloc.add(const StartVoiceRecordingEvent());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (previous, current) =>
          previous.transcribedVoiceText != current.transcribedVoiceText &&
          current.transcribedVoiceText != null,
      listener: (context, state) {
        if (state.transcribedVoiceText != null) {
          _controller.text = state.transcribedVoiceText!;
          context.read<ChatBloc>().add(const ClearTranscribedTextEvent());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Detector'),
          actions: [
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: state.isModelInstalled
                            ? 'Model file installed'
                            : 'Model file not installed',
                        child: Chip(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            state.isModelInstalled
                                ? Icons.download_done
                                : Icons.download_outlined,
                            size: 16,
                            color: state.isModelInstalled
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                          label: Text(
                            state.isModelInstalled
                                ? 'Installed'
                                : 'Not Installed',
                            style: TextStyle(
                              fontSize: 11,
                              color: state.isModelInstalled
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: state.isModelInstalled
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : Colors.orangeAccent.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: state.isModelInitialized
                            ? 'Model loaded in memory'
                            : 'Model not initialized',
                        child: Chip(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            state.isModelInitialized
                                ? Icons.bolt
                                : Icons.pause_circle_outline,
                            size: 16,
                            color: state.isModelInitialized
                                ? Colors.lightBlueAccent
                                : Colors.grey,
                          ),
                          label: Text(
                            state.isModelInitialized
                                ? 'Initialized'
                                : 'Not Init',
                            style: TextStyle(
                              fontSize: 11,
                              color: state.isModelInitialized
                                  ? Colors.lightBlueAccent
                                  : Colors.grey,
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: state.isModelInitialized
                                ? Colors.lightBlueAccent.withValues(alpha: 0.5)
                                : Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Describe an expense in any language or tap the microphone to speak. Your text is analyzed only on this device.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isUser = message.isUser;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.85,
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blueAccent.shade700
                                : Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                            border: !isUser
                                ? Border.all(
                                    color: Colors.grey.shade800,
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Text(
                            message.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.isRecordingVoice) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    color: Colors.red.shade900.withValues(alpha: 0.8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Listening... Tap mic again to stop recording',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state.isTranscribingVoice) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blueGrey.shade900,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Transcribing speech with Whisper...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                if (state.isDownloading) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blueGrey.shade900,
                    child: Column(
                      children: [
                        const Text(
                          'Downloading offline Gemma model...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: state.downloadProgress),
                        const SizedBox(height: 4),
                        Text(
                          '${(state.downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }
                if (state.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) => TextField(
                        controller: _controller,
                        enabled: !state.isDownloading &&
                            !state.isGenerating &&
                            !state.isTranscribingVoice,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Paid ₹450 for lunch',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      final isBusy = state.isGenerating ||
                          state.isDownloading ||
                          state.isTranscribingVoice;
                      return IconButton(
                        icon: Icon(
                          state.isRecordingVoice ? Icons.stop : Icons.mic,
                          color: state.isRecordingVoice
                              ? Colors.redAccent
                              : Colors.lightBlueAccent,
                        ),
                        onPressed:
                            isBusy ? null : () => _toggleVoiceRecording(state),
                      );
                    },
                  ),
                  const SizedBox(width: 2),
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) => IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: state.isGenerating ||
                              state.isDownloading ||
                              state.isRecordingVoice ||
                              state.isTranscribingVoice
                          ? null
                          : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
