import 'package:equatable/equatable.dart';

import 'mobile_action.dart';

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final bool? isCompleteExpense;
  final MobileAction? action;
  final MobileActionResult? actionResult;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isCompleteExpense,
    this.action,
    this.actionResult,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    bool? isCompleteExpense,
    MobileAction? action,
    MobileActionResult? actionResult,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      isCompleteExpense: isCompleteExpense ?? this.isCompleteExpense,
      action: action ?? this.action,
      actionResult: actionResult ?? this.actionResult,
    );
  }

  @override
  List<Object?> get props =>
      [id, text, isUser, isCompleteExpense, action, actionResult];
}
