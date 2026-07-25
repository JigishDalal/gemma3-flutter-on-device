import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Full-screen overlay shown while the mic is recording or Whisper is
/// transcribing. Displays concentric ripple rings, a state label and a
/// "Stop" button.
class VoiceRecordingOverlay extends StatefulWidget {
  final bool isTranscribing; // false = recording, true = whisper running
  final VoidCallback onStop;

  const VoiceRecordingOverlay({
    super.key,
    required this.isTranscribing,
    required this.onStop,
  });

  @override
  State<VoiceRecordingOverlay> createState() => _VoiceRecordingOverlayState();
}

class _VoiceRecordingOverlayState extends State<VoiceRecordingOverlay>
    with TickerProviderStateMixin {
  // Three staggered ripple rings
  late final List<AnimationController> _rippleCtrs;
  late final List<Animation<double>> _rippleScales;
  late final List<Animation<double>> _rippleOpacities;

  // Mic icon pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Entry / exit fade
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // ── Fade-in ────────────────────────────────────────────────────────────
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // ── Ripple rings ───────────────────────────────────────────────────────
    _rippleCtrs = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      ),
    );

    _rippleScales = _rippleCtrs
        .map(
          (c) => Tween<double>(begin: 0.4, end: 1.6).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOut),
          ),
        )
        .toList();

    _rippleOpacities = _rippleCtrs
        .map(
          (c) => Tween<double>(begin: 0.6, end: 0.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOut),
          ),
        )
        .toList();

    // Stagger each ring by 600 ms
    for (var i = 0; i < _rippleCtrs.length; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) _rippleCtrs[i].repeat();
      });
    }

    // ── Mic pulse ──────────────────────────────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final c in _rippleCtrs) {
      c.dispose();
    }
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Color get _ringColor => widget.isTranscribing
      ? AppTheme.accentGradientC   // sky-blue while whisper runs
      : const Color(0xFFEF4444);   // coral/red while recording

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: AppTheme.bgBase.withValues(alpha: 0.92),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Ripple + mic orb ─────────────────────────────────────────
            SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [..._rippleCtrs, _pulseCtrl]),
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple rings (back to front)
                      for (var i = 0; i < 3; i++)
                        Transform.scale(
                          scale: _rippleScales[i].value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _ringColor.withValues(
                                  alpha: _rippleOpacities[i].value,
                                ),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      // Central mic button
                      Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: widget.isTranscribing
                                  ? [
                                      AppTheme.accentGradientC,
                                      AppTheme.accentGradientB,
                                    ]
                                  : [
                                      const Color(0xFFFF6B6B),
                                      const Color(0xFFB91C1C),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _ringColor.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isTranscribing
                                ? Icons.graphic_eq_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // ── State label ───────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.isTranscribing
                    ? 'TRANSCRIBING WITH WHISPER'
                    : 'LISTENING',
                key: ValueKey(widget.isTranscribing),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2.2,
                      color: AppTheme.textSecondary,
                    ),
              ),
            ),

            const SizedBox(height: 8),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.isTranscribing
                    ? 'Processing your voice…'
                    : 'Speak now, tap Stop when done',
                key: ValueKey('sub_${widget.isTranscribing}'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    ),
              ),
            ),

            const SizedBox(height: 44),

            // ── Stop button ───────────────────────────────────────────────
            if (!widget.isTranscribing)
              _StopButton(onTap: widget.onStop),
          ],
        ),
      ),
    );
  }
}

class _StopButton extends StatefulWidget {
  final VoidCallback onTap;
  const _StopButton({required this.onTap});

  @override
  State<_StopButton> createState() => _StopButtonState();
}

class _StopButtonState extends State<_StopButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
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
        scale: _ctrl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Stop Recording',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB91C1C),
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
