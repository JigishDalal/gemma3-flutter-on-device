import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final bool? isCompleteExpense;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isCompleteExpense,
  });

  @override
  List<Object?> get props => [id, text, isUser, isCompleteExpense];
}
