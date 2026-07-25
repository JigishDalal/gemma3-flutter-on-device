import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// The visual state that drives the orb's colour and animation.
enum OrbState { idle, listening, thinking, done, error }

/// An animated iridescent AI orb inspired by the Dribbble voice-AI design.
///
/// It renders a gradient sphere that pulses and rotates. The colour palette
/// shifts depending on [state].
class AnimatedOrb extends StatefulWidget {
  final OrbState state;
  final double size;

  const AnimatedOrb({
    super.key,
    this.state = OrbState.idle,
    this.size = 160,
  });

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb>
    with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _colorCtrl;

  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _colorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _colorCtrl.forward(from: 0);
      _updatePulseSpeed();
    }
  }

  void _updatePulseSpeed() {
    switch (widget.state) {
      case OrbState.listening:
        _pulseCtrl.duration = const Duration(milliseconds: 500);
        _rotateCtrl.duration = const Duration(seconds: 3);
      case OrbState.thinking:
        _pulseCtrl.duration = const Duration(milliseconds: 800);
        _rotateCtrl.duration = const Duration(seconds: 2);
      case OrbState.done:
        _pulseCtrl.duration = const Duration(milliseconds: 2000);
        _rotateCtrl.duration = const Duration(seconds: 8);
      case OrbState.error:
        _pulseCtrl.duration = const Duration(milliseconds: 300);
        _rotateCtrl.duration = const Duration(seconds: 4);
      case OrbState.idle:
        _pulseCtrl.duration = const Duration(milliseconds: 1400);
        _rotateCtrl.duration = const Duration(seconds: 6);
    }
    _pulseCtrl.reset();
    _pulseCtrl.repeat(reverse: true);
  }

  List<Color> _colorsForState(OrbState s) {
    switch (s) {
      case OrbState.idle:
        return [
          AppTheme.accentGradientA,
          AppTheme.accentGradientB,
          AppTheme.accentGradientC,
        ];
      case OrbState.listening:
        return [
          const Color(0xFFFF6B6B),
          const Color(0xFFFF8E53),
          const Color(0xFFFFD93D),
        ];
      case OrbState.thinking:
        return [
          const Color(0xFF6C63FF),
          const Color(0xFF3ECFCF),
          const Color(0xFF9B59B6),
        ];
      case OrbState.done:
        return [
          const Color(0xFF56CCF2),
          const Color(0xFF2F80ED),
          const Color(0xFF43E97B),
        ];
      case OrbState.error:
        return [
          const Color(0xFFEB5757),
          const Color(0xFFB91C1C),
          const Color(0xFFF59E0B),
        ];
    }
  }

  String _labelForState(OrbState s) {
    switch (s) {
      case OrbState.idle:
        return 'TAP TO SPEAK';
      case OrbState.listening:
        return 'LISTENING';
      case OrbState.thinking:
        return 'THINKING';
      case OrbState.done:
        return 'DONE';
      case OrbState.error:
        return 'ERROR';
    }
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_rotateCtrl, _pulseCtrl, _colorCtrl]),
          builder: (context, _) {
            final colors = _colorsForState(widget.state);
            return Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors[1].withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.2),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _OrbPainter(
                    rotation: _rotateCtrl.value * 2 * math.pi,
                    colors: colors,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _labelForState(widget.state),
            key: ValueKey(widget.state),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 2.0,
                ),
          ),
        ),
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double rotation;
  final List<Color> colors;

  _OrbPainter({required this.rotation, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // White base circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white,
    );

    // Clip to circle
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Rotating gradient blob 1
    final grad1 = Paint()
      ..shader = RadialGradient(
        colors: [colors[0].withValues(alpha: 0.9), colors[0].withValues(alpha: 0.0)],
        radius: 0.7,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final offset1 = Offset(
      center.dx + radius * 0.3 * math.cos(rotation),
      center.dy + radius * 0.3 * math.sin(rotation),
    );
    canvas.drawCircle(offset1, radius * 0.75, grad1);

    // Rotating gradient blob 2
    final grad2 = Paint()
      ..shader = RadialGradient(
        colors: [colors[1].withValues(alpha: 0.85), colors[1].withValues(alpha: 0.0)],
        radius: 0.7,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final offset2 = Offset(
      center.dx + radius * 0.3 * math.cos(rotation + 2.1),
      center.dy + radius * 0.3 * math.sin(rotation + 2.1),
    );
    canvas.drawCircle(offset2, radius * 0.65, grad2);

    // Rotating gradient blob 3
    final grad3 = Paint()
      ..shader = RadialGradient(
        colors: [colors[2].withValues(alpha: 0.8), colors[2].withValues(alpha: 0.0)],
        radius: 0.7,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final offset3 = Offset(
      center.dx + radius * 0.25 * math.cos(rotation + 4.2),
      center.dy + radius * 0.25 * math.sin(rotation + 4.2),
    );
    canvas.drawCircle(offset3, radius * 0.6, grad3);

    // Specular highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.5), Colors.transparent],
        radius: 0.5,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.25),
      radius * 0.45,
      highlightPaint,
    );

    canvas.restore();

    // Rim / border glow
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.rotation != rotation || old.colors != colors;
}
