import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/repositories_impl/model_repository_impl.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/screens/chat_screen.dart';

void main() {
  runApp(const AIEdgeGalleryApp());
}

class AIEdgeGalleryApp extends StatelessWidget {
  const AIEdgeGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject dependencies
    final repository = ModelRepositoryImpl();

    return BlocProvider<ChatBloc>(
      create: (_) => ChatBloc(repository: repository),
      child: MaterialApp(
        title: 'Expense Detector',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: Colors.blueAccent,
        ),
        home: const ChatScreen(),
      ),
    );
  }
}
