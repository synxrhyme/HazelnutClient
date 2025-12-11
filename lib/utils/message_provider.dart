import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hazelnut/utils/database_service.dart';
import 'package:hazelnut/utils/models.dart';
import 'package:hazelnut/utils/secure_storage_service.dart';

class MessageProvider extends ChangeNotifier {
  MessageProvider._internal() { loadAll(); }
  static final MessageProvider _instance = MessageProvider._internal();

  factory MessageProvider() {
    return _instance;
  }

  final Map<int, List<MessageModel>> _messagesByChat = {};
  List<MessageModel> messagesForChat(int chatId) => _messagesByChat[chatId] ?? [];

  String? _userId;
  String? get userId => _userId;

  Future<void> loadUserId(SecureStorageService secureStorage) async {
    _userId = await secureStorage.getToken("userId");
    notifyListeners();
  }

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

  Future<void> addMessage(MessageModel message, bool update) async {
    await DatabaseService().insertMessageIntoDb(message);
    if (update) loadAll();

    notifyListeners();
  }
}

final messageProvider = ChangeNotifierProvider<MessageProvider>((ref) {
  return MessageProvider();
});

int stableHash(String input) {
  int hash = 0;
  for (int i = 0; i < input.length; i++) {
    hash = (hash * 31 + input.codeUnitAt(i)) & 0x7fffffff;
  }
  return hash;
}

Color getAccentFromString(String input) {
  final hash = stableHash(input);
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor();
}