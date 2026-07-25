import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../blocs/chat/chat_bloc.dart';

/// App bar row showing the app name and a live [ModelStatusDot].
class ChatTopBar extends StatelessWidget {
  const ChatTopBar({super.key});

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 12, color: Colors.blueAccent),
                SizedBox(width: 4),
                Text(
                  'Mobile Actions ⚡',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (_, state) => ModelStatusDot(state: state),
          ),
        ],
      ),
    );
  }
}

/// A 10×10 coloured dot conveying the model's installation/initialization state.
///
/// Green = ready, Amber = installed but not loaded, Grey = not installed.
class ModelStatusDot extends StatelessWidget {
  final ChatState state;

  const ModelStatusDot({super.key, required this.state});

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
