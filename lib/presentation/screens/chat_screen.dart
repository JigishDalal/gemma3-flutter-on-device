import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/chat/chat_bloc.dart';
import '../widgets/animated_orb.dart';
import '../widgets/frosted_chat_bubble.dart';
import '../widgets/download_progress_card.dart';
import '../widgets/voice_recording_overlay.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

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

  OrbState _orbState(ChatState s) {
    if (s.isGenerating) return OrbState.thinking;
    if (s.errorMessage != null) return OrbState.error;
    if (s.messages.isNotEmpty) return OrbState.done;
    return OrbState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, cur) =>
          prev.transcribedVoiceText != cur.transcribedVoiceText &&
          cur.transcribedVoiceText != null,
      listener: (context, state) {
        // Fill text field with transcribed speech; user can review then send
        if (state.transcribedVoiceText != null) {
          _textCtrl.text = state.transcribedVoiceText!;
          _textCtrl.selection = TextSelection.collapsed(
            offset: _textCtrl.text.length,
          );
          context.read<ChatBloc>().add(const ClearTranscribedTextEvent());
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Silk background ─────────────────────────────────────────
            const _AnimatedSilkBg(),

            // ── Main content ─────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // ── App bar ────────────────────────────────────────────
                  _TopBar(),

                  // ── Messages list ──────────────────────────────────────
                  Expanded(
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state.messages.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );
                        return ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          itemCount: state.messages.length,
                          itemBuilder: (_, i) {
                            final msg = state.messages[i];
                            return FrostedChatBubble(
                              text: msg.text,
                              isUser: msg.isUser,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Orb (shrinks when messages present) ───────────────
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      return AnimatedPadding(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          vertical: state.messages.isEmpty ? 28 : 12,
                        ),
                        child: AnimatedOrb(
                          state: _orbState(state),
                          size: state.messages.isEmpty ? 170 : 110,
                        ),
                      );
                    },
                  ),

                  // ── Download progress ──────────────────────────────────
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state.isDownloading) {
                        return DownloadProgressCard(
                          progress: state.downloadProgress,
                        );
                      }
                      if (state.errorMessage != null) {
                        return _ErrorBanner(message: state.errorMessage!);
                      }
                      if (state.isGenerating) {
                        return _InfoBanner(
                          icon: Icons.auto_awesome,
                          color: AppTheme.accentGradientB,
                          label: 'Gemma is thinking…',
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // ── Always-visible input bar ───────────────────────────
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      final busy = state.isGenerating ||
                          state.isDownloading ||
                          state.isRecordingVoice ||
                          state.isTranscribingVoice;
                      return _PersistentInputBar(
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

            // ── Voice recording overlay (above everything) ────────────────
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final showOverlay =
                    state.isRecordingVoice || state.isTranscribingVoice;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: showOverlay
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

// ─────────────────────────────────────────────────────────────────────────────
// Always-visible input bar
// ─────────────────────────────────────────────────────────────────────────────

class _PersistentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool isRecording;
  final bool isBusy;
  final VoidCallback onSend;
  final VoidCallback onMicTap;

  const _PersistentInputBar({
    required this.controller,
    required this.enabled,
    required this.isRecording,
    required this.isBusy,
    required this.onSend,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(width: 18),
                // ── Text field ─────────────────────────────────────────
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Type something…',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.65),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                // ── Send button ────────────────────────────────────────
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final hasText = controller.text.trim().isNotEmpty;
                    return AnimatedOpacity(
                      opacity: hasText ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: hasText
                          ? IconButton(
                              icon: const Icon(Icons.send_rounded),
                              color: AppTheme.accentGradientB,
                              onPressed: enabled ? onSend : null,
                            )
                          : const SizedBox(width: 4),
                    );
                  },
                ),
                // ── Mic button ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: _MicButton(
                    isRecording: isRecording,
                    isBusy: isBusy,
                    onTap: onMicTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final bool isBusy;
  final VoidCallback onTap;

  const _MicButton({
    required this.isRecording,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isBusy && !isRecording
                ? [Colors.grey.shade300, Colors.grey.shade400]
                : [
                    AppTheme.accentGradientA,
                    AppTheme.accentGradientB,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGradientB.withValues(alpha: isBusy ? 0 : 0.35),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.mic_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status banners
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB91C1C),
                      fontSize: 13,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            'Gemma 3',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '· On Device',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
          ),
          const Spacer(),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (_, state) => _ModelStatusDot(state: state),
          ),
        ],
      ),
    );
  }
}

class _ModelStatusDot extends StatelessWidget {
  final ChatState state;
  const _ModelStatusDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String tip;
    if (state.isModelInitialized) {
      color = const Color(0xFF22C55E);
      tip = 'Model ready';
    } else if (state.isModelInstalled) {
      color = const Color(0xFFF59E0B);
      tip = 'Model installed';
    } else {
      color = const Color(0xFFD1D5DB);
      tip = 'Model not installed';
    }
    return Tooltip(
      message: tip,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated silk background
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedSilkBg extends StatefulWidget {
  const _AnimatedSilkBg();

  @override
  State<_AnimatedSilkBg> createState() => _AnimatedSilkBgState();
}

class _AnimatedSilkBgState extends State<_AnimatedSilkBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _SilkPainter(_ctrl.value),
      ),
    );
  }
}

class _SilkPainter extends CustomPainter {
  final double t;
  _SilkPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.bgBase);

    void blob(Offset center, double radius, List<Color> colors) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: colors).createShader(
            Rect.fromCircle(center: center, radius: radius),
          ),
      );
    }

    blob(
      Offset(
        size.width * (0.1 + 0.08 * math.sin(t * 2 * math.pi)),
        size.height * 0.25,
      ),
      size.width * 0.55,
      [
        const Color(0xFFE9D5FF).withValues(alpha: 0.5),
        Colors.transparent,
      ],
    );
    blob(
      Offset(
        size.width * 0.9,
        size.height * (0.5 + 0.07 * math.cos(t * 2 * math.pi + 1.5)),
      ),
      size.width * 0.5,
      [
        const Color(0xFFBAE6FD).withValues(alpha: 0.45),
        Colors.transparent,
      ],
    );
    blob(
      Offset(
        size.width * (0.45 + 0.05 * math.sin(t * 2 * math.pi + 3)),
        size.height * 0.9,
      ),
      size.width * 0.6,
      [
        const Color(0xFFFEF08A).withValues(alpha: 0.4),
        Colors.transparent,
      ],
    );
  }

  @override
  bool shouldRepaint(_SilkPainter old) => old.t != t;
}
