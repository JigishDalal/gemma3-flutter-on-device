import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A full-screen animated silk/ribbon background using [CustomPainter].
///
/// Three slow-drifting gradient blobs create the iridescent pearl feel
/// inspired by the Dribbble voice-AI design.
class AnimatedSilkBackground extends StatefulWidget {
  const AnimatedSilkBackground({super.key});

  @override
  State<AnimatedSilkBackground> createState() => _AnimatedSilkBackgroundState();
}

class _AnimatedSilkBackgroundState extends State<AnimatedSilkBackground>
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
    // Base colour
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
      [const Color(0xFFE9D5FF).withValues(alpha: 0.5), Colors.transparent],
    );
    blob(
      Offset(
        size.width * 0.9,
        size.height * (0.5 + 0.07 * math.cos(t * 2 * math.pi + 1.5)),
      ),
      size.width * 0.5,
      [const Color(0xFFBAE6FD).withValues(alpha: 0.45), Colors.transparent],
    );
    blob(
      Offset(
        size.width * (0.45 + 0.05 * math.sin(t * 2 * math.pi + 3)),
        size.height * 0.9,
      ),
      size.width * 0.6,
      [const Color(0xFFFEF08A).withValues(alpha: 0.4), Colors.transparent],
    );
  }

  @override
  bool shouldRepaint(_SilkPainter old) => old.t != t;
}
