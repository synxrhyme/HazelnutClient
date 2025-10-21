import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hazelnut/utils/database_service.dart';
import 'package:hazelnut/utils/models.dart';

class MessageProvider extends ChangeNotifier {
  MessageProvider._internal();
  static final MessageProvider _instance = MessageProvider._internal();

  factory MessageProvider() {
    return _instance;
  }

  final Map<int, List<MessageModel>> _messagesByChat = {};
  List<MessageModel> messagesForChat(int chatId) => _messagesByChat[chatId] ?? [];

  Future<void> loadAll() async {
    List<ChatModel> chats = await DatabaseService().loadAllChats();

    if (chats.isEmpty) {
      _messagesByChat.clear();
      return;
    }

    for (ChatModel chat in chats) {
      final loaded = await DatabaseService().loadMessagesForChat(chat.chatId);
      _messagesByChat[chat.chatId] = loaded;
    }

    notifyListeners();
  }

  Future<void> addMessage(MessageModel message) async {
    await DatabaseService().insertMessageIntoDb(message);
    loadAll();

    notifyListeners();
  }
}

final messageProvider = ChangeNotifierProvider<MessageProvider>((ref) {
  return MessageProvider();
});

Color getAccentFromString(String input) {
  final hash = input.hashCode;
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor();
}