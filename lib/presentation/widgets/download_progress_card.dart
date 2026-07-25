import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';

/// Animated download progress card shown while the Gemma model is downloading.
class DownloadProgressCard extends StatefulWidget {
  final double progress; // 0.0 – 1.0

  const DownloadProgressCard({super.key, required this.progress});

  @override
  State<DownloadProgressCard> createState() => _DownloadProgressCardState();
}

class _DownloadProgressCardState extends State<DownloadProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.progress * 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Circular arc progress
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: widget.progress,
                      strokeWidth: 4,
                      backgroundColor:
                          AppTheme.accentGradientB.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.accentGradientB,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentGradientB,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.downloadingTitle,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.downloadingSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Linear shimmer bar
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: widget.progress,
                  minHeight: 6,
                  backgroundColor:
                      AppTheme.accentGradientB.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                      AppTheme.accentGradientA,
                      AppTheme.accentGradientB,
                      _shimmerCtrl.value,
                    )!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
