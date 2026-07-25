import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/chat/chat_bloc.dart';
import '../widgets/animated_orb.dart';
import '../widgets/download_progress_card.dart';
import 'chat_screen.dart';

/// Shown on first launch (or whenever the model is not installed).
/// Gives the user a clear call-to-action to download the Gemma 3 model.
class ModelSetupScreen extends StatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, cur) =>
          prev.isModelInstalled != cur.isModelInstalled &&
          cur.isModelInstalled,
      listener: (context, state) {
        // Model finished downloading — go to chat
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const ChatScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ── Silk background ───────────────────────────────────────────
            const _SilkBackground(),
            // ── Main content ──────────────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      // Orb
                      const AnimatedOrb(state: OrbState.idle, size: 160),
                      const SizedBox(height: 40),
                      // Headline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Text(
                          'On-Device AI\nPrivate by Design',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                height: 1.25,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 44),
                        child: Text(
                          'Gemma 3 runs entirely on your device. '
                          'Your data never leaves your phone.\n'
                          'Download once (~150 MB) to get started.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.65,
                              ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      // ── Download section ──────────────────────────────
                      BlocBuilder<ChatBloc, ChatState>(
                        builder: (context, state) {
                          if (state.isDownloading) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DownloadProgressCard(
                                  progress: state.downloadProgress,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please keep the app open…',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ],
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (state.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Colors.red.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Text(
                                      state.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFB91C1C),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Download CTA button
                                _DownloadButton(
                                  label: state.errorMessage != null
                                      ? 'Retry Download'
                                      : 'Download Gemma 3',
                                  onTap: () => context
                                      .read<ChatBloc>()
                                      .add(const DownloadModelEvent()),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Wi-Fi recommended · One-time download',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Download CTA button ────────────────────────────────────────────────────

class _DownloadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _DownloadButton({required this.label, required this.onTap});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.accentGradientA,
                AppTheme.accentGradientB,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGradientB.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Silk background painter ────────────────────────────────────────────────

class _SilkBackground extends StatefulWidget {
  const _SilkBackground();

  @override
  State<_SilkBackground> createState() => _SilkBackgroundState();
}

class _SilkBackgroundState extends State<_SilkBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
    // Base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppTheme.bgBase,
    );

    final blobs = [
      _BlobConfig(
        center: Offset(
          size.width * (0.15 + 0.1 * math.sin(t * 2 * math.pi)),
          size.height * (0.2 + 0.08 * math.cos(t * 2 * math.pi)),
        ),
        radius: size.width * 0.6,
        colors: [
          const Color(0xFFE0C3FC).withValues(alpha: 0.55),
          Colors.transparent,
        ],
      ),
      _BlobConfig(
        center: Offset(
          size.width * (0.85 + 0.08 * math.cos(t * 2 * math.pi + 1)),
          size.height * (0.35 + 0.1 * math.sin(t * 2 * math.pi + 1)),
        ),
        radius: size.width * 0.55,
        colors: [
          const Color(0xFFB2EBF2).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ),
      _BlobConfig(
        center: Offset(
          size.width * (0.5 + 0.06 * math.sin(t * 2 * math.pi + 2)),
          size.height * (0.85 + 0.06 * math.cos(t * 2 * math.pi + 2)),
        ),
        radius: size.width * 0.65,
        colors: [
          const Color(0xFFFFF9C4).withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ),
    ];

    for (final b in blobs) {
      canvas.drawCircle(
        b.center,
        b.radius,
        Paint()
          ..shader = RadialGradient(
            colors: b.colors,
          ).createShader(Rect.fromCircle(center: b.center, radius: b.radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_SilkPainter old) => old.t != t;
}

class _BlobConfig {
  final Offset center;
  final double radius;
  final List<Color> colors;
  const _BlobConfig({
    required this.center,
    required this.radius,
    required this.colors,
  });
}
