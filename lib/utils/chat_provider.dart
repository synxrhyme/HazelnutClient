import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hazelnut/utils/database_service.dart';
import 'package:hazelnut/utils/models.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider._internal();
  static final ChatProvider _instance = ChatProvider._internal();

  factory ChatProvider() {
    return _instance;
  }

  List<ChatModel> _chats = [];
  List<ChatModel> get chats => _chats;

  Future<void> loadChats() async {
    _chats = await DatabaseService().loadAllChats();
    notifyListeners();
  }

  Future<void> addChat(ChatModel chat) async {
    await DatabaseService().insertChatIntoDb(chat);
    await loadChats();
  }
}

final chatProvider = ChangeNotifierProvider<ChatProvider>((ref) {
  return ChatProvider();
});