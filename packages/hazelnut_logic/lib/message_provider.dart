import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_bus.dart';
import 'package:hazelnut_shared/models.dart';

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

  @override
  void dispose() {
    _signOutSub?.cancel();
    super.dispose();
  }
}

final messageProviderProvider = ChangeNotifierProvider<MessageProvider>((ref) {
  final deps = ref.watch(appDependenciesProvider);
  return MessageProvider(deps.secureStorageService, deps.databaseService, deps.webSocketBus);
});