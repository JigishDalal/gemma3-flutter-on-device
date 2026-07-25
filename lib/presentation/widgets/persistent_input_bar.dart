import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';

/// A frosted-glass input row that is always visible at the bottom of the screen.
/// Contains a [TextField], an animated send button, and a mic button.
class PersistentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool isRecording;
  final bool isBusy;
  final VoidCallback onSend;
  final VoidCallback onMicTap;

  const PersistentInputBar({
    super.key,
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
                      hintText: AppStrings.inputHintText,
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
                // Send button — fades in only when text is present
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
                // Mic button
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: InputMicButton(
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

/// Gradient circular mic button used inside [PersistentInputBar].
class InputMicButton extends StatelessWidget {
  final bool isRecording;
  final bool isBusy;
  final VoidCallback onTap;

  const InputMicButton({
    super.key,
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
              color: AppTheme.accentGradientB
                  .withValues(alpha: isBusy ? 0 : 0.35),
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
