import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/chat/chat_bloc.dart';
import '../widgets/animated_orb.dart';
import '../widgets/animated_silk_background.dart';
import '../widgets/chat_top_bar.dart';
import '../widgets/download_progress_card.dart';
import '../widgets/frosted_chat_bubble.dart';
import '../widgets/persistent_input_bar.dart';
import '../widgets/status_banners.dart';
import '../widgets/voice_recording_overlay.dart';

/// The main chat screen.
///
/// This widget is intentionally kept thin — it only owns controllers,
/// handles user intent (send / mic), and composes the child widgets.
/// All visual sub-components live in `lib/presentation/widgets/`.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Intents ────────────────────────────────────────────────────────────────

  void _sendMessage() {
    final msg = _textCtrl.text.trim();
    if (msg.isEmpty) return;
    context.read<ChatBloc>().add(SendMessageEvent(message: msg));
    _textCtrl.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();
  }

  void _onMicTap(ChatState state) {
    final bloc = context.read<ChatBloc>();
    if (state.isRecordingVoice) {
      bloc.add(const StopVoiceRecordingEvent());
    } else {
      FocusScope.of(context).unfocus();
      bloc.add(const StartVoiceRecordingEvent());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Orb state mapping ──────────────────────────────────────────────────────

  OrbState _orbState(ChatState s) {
    if (s.isGenerating) return OrbState.thinking;
    if (s.errorMessage != null) return OrbState.error;
    if (s.messages.isNotEmpty) return OrbState.done;
    return OrbState.idle;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, cur) =>
          prev.transcribedVoiceText != cur.transcribedVoiceText &&
          cur.transcribedVoiceText != null,
      listener: (context, state) {
        // Fill the text field so the user can review before sending
        if (state.transcribedVoiceText != null) {
          _textCtrl.text = state.transcribedVoiceText!;
          _textCtrl.selection =
              TextSelection.collapsed(offset: _textCtrl.text.length);
          context.read<ChatBloc>().add(const ClearTranscribedTextEvent());
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Layer 1 — silk background
            const AnimatedSilkBackground(),

            // Layer 2 — main content
            SafeArea(
              child: Column(
                children: [
                  const ChatTopBar(),

                  // Messages list
                  Expanded(child: _MessagesList(scrollCtrl: _scrollCtrl)),

                  // Orb (shrinks when messages exist)
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) => AnimatedPadding(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        vertical: state.messages.isEmpty ? 28 : 12,
                      ),
                      child: AnimatedOrb(
                        state: _orbState(state),
                        size: state.messages.isEmpty ? 170 : 110,
                      ),
                    ),
                  ),

                  // Status / download area
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state.isDownloading) {
                        return DownloadProgressCard(
                          progress: state.downloadProgress,
                        );
                      }
                      if (state.errorMessage != null) {
                        return ErrorBanner(message: state.errorMessage!);
                      }
                      if (state.isGenerating) {
                        return const InfoBanner(
                          icon: Icons.auto_awesome,
                          color: Color(0xFF9B59B6),
                          label: 'Gemma is thinking…',
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Always-visible text + mic input bar
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      final busy = state.isGenerating ||
                          state.isDownloading ||
                          state.isRecordingVoice ||
                          state.isTranscribingVoice;
                      return PersistentInputBar(
                        controller: _textCtrl,
                        enabled: !busy,
                        isRecording: state.isRecordingVoice,
                        isBusy: busy,
                        onSend: _sendMessage,
                        onMicTap: () => _onMicTap(state),
                      );
                    },
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),

            // Layer 3 — voice recording overlay (on top of everything)
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final show =
                    state.isRecordingVoice || state.isTranscribingVoice;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: show
                      ? VoiceRecordingOverlay(
                          key: const ValueKey('overlay'),
                          isTranscribing: state.isTranscribingVoice,
                          onStop: () => context
                              .read<ChatBloc>()
                              .add(const StopVoiceRecordingEvent()),
                        )
                      : const SizedBox.shrink(key: ValueKey('no_overlay')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers (tightly coupled to this screen only) ─────────────────────

/// Renders the scrollable list of chat bubbles.
/// Extracted as a private widget to keep [_ChatScreenState.build] readable.
class _MessagesList extends StatelessWidget {
  final ScrollController scrollCtrl;

  const _MessagesList({required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (prev, cur) => prev.messages != cur.messages,
      builder: (context, state) {
        if (state.messages.isEmpty) return const SizedBox.shrink();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollCtrl.hasClients) {
            scrollCtrl.animateTo(
              scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          itemCount: state.messages.length,
          itemBuilder: (_, i) {
            final msg = state.messages[i];
            return FrostedChatBubble(text: msg.text, isUser: msg.isUser);
          },
        );
      },
    );
  }
}
