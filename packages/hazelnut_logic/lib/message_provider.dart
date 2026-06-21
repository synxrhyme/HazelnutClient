import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hazelnut_shared/app_dependencies.dart';
import 'package:hazelnut_shared/database_service.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_shared/secure_storage_service.dart';
import 'package:hazelnut_shared/websocket_bus.dart';

class MessageProvider extends ChangeNotifier {
  MessageProvider(this.secureStorage, this.databaseService, this.webSocketBus) {
    loadAll();
    _signOutSub = webSocketBus.on('USER_SIGNED_OUT').listen((_) => loadAll());
  }

  final SecureStorageService secureStorage;
  final DatabaseService databaseService;
  final WebSocketBus webSocketBus;
  StreamSubscription? _signOutSub;

  final Map<int, List<MessageModel>> _messagesByChat = {};
  List<MessageModel> messagesForChat(int chatId) => _messagesByChat[chatId] ?? [];

  String? _userId;
  String? get userId => _userId;

  Future<void> loadUserId(SecureStorageService secureStorage) async {
    _userId = await secureStorage.getToken("userId");
    notifyListeners();
  }

  Future<void> loadAll() async {
    List<ChatModel> chats = await databaseService.loadAllChats();

    if (chats.isEmpty) {
      _messagesByChat.clear();
      return;
    }

    for (ChatModel chat in chats) {
      final loaded = await databaseService.loadMessagesForChat(chat.chatId);
      _messagesByChat[chat.chatId] = loaded;
    }

    notifyListeners();
  }

  Future<void> addMessage(MessageModel message, bool update) async {
    await databaseService.insertMessageIntoDb(message);
    if (update) loadAll();

    notifyListeners();
  }

  @override
  void dispose() {
    _signOutSub?.cancel();
    super.dispose();
  }
}