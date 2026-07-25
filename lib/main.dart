import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories_impl/model_repository_impl.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/model_setup_screen.dart';

void main() {
  runApp(const GemmaApp());
}

class GemmaApp extends StatelessWidget {
  const GemmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ModelRepositoryImpl();

    return BlocProvider<ChatBloc>(
      create: (_) => ChatBloc(repository: repository),
      child: MaterialApp(
        title: 'Gemma 3 · On Device',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AppRouter(),
      ),
    );
  }
}

/// Decides which screen to show based on model installation state.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (prev, cur) =>
          prev.isModelInstalled != cur.isModelInstalled,
      builder: (context, state) {
        // Show setup screen until model is installed
        if (!state.isModelInstalled) {
          return const ModelSetupScreen();
        }
        return const ChatScreen();
      },
    );
  }
}
