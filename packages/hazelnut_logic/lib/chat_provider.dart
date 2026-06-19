import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hazelnut_shared/app_dependencies.dart';
import 'package:hazelnut_shared/database_service.dart';
import 'package:hazelnut_shared/models.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this.databaseService);

  final DatabaseService databaseService;

  List<ChatModel> _chats = [];
  List<ChatModel> get chats => _chats;

  Future<void> loadChats() async {
    _chats = await databaseService.loadAllChats();
    notifyListeners();
  }

  Future<void> addChat(ChatModel chat) async {
    await databaseService.insertChatIntoDb(chat);
    await loadChats();
  }
}

final chatProviderProvider = ChangeNotifierProvider<ChatProvider>((ref) {
  final deps = ref.watch(appDependenciesProvider);
  return ChatProvider(deps.databaseService);
});