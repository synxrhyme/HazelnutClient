import 'package:hazelnut/utils/websocket_service_bridge.dart';
import 'package:hazelnut_shared/database_service.dart' as shared;
import 'package:hazelnut_shared/models.dart';

class DatabaseService implements shared.DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  shared.DatabaseService get _service => appDependencies.databaseService;

  Future<void> init() async {
    // Already initialized in createDependencies
  }

  @override
  Future<void> insertChatIntoDb(ChatModel chat) => _service.insertChatIntoDb(chat);

  @override
  Future<void> insertMessageIntoDb(MessageModel message) => _service.insertMessageIntoDb(message);

  @override
  Future<void> insertUserIntoDb(UserModel user) => _service.insertUserIntoDb(user);

  @override
  Future<void> addUserToChat(int chatId, UserModel user) => _service.addUserToChat(chatId, user);

  @override
  Future<List<UserModel>> getUsersForChat(int chatId) => _service.getUsersForChat(chatId);

  @override
  Future<List<ChatModel>> loadAllChats() => _service.loadAllChats();

  @override
  Future<List<MessageModel>> loadMessagesForChat(int chatId) => _service.loadMessagesForChat(chatId);

  @override
  Future<List<MessageModel>?> getPendingMessages() => _service.getPendingMessages();

  @override
  Future<int> getLatestMessageId() => _service.getLatestMessageId();

  @override
  Future<List<UserModel>> loadAllUsers() => _service.loadAllUsers();

  @override
  void clearAll() => _service.clearAll();

  // Additional helper methods that might be called
  Future<void> saveChat(ChatModel chat) => insertChatIntoDb(chat);
  Future<void> saveMessage(MessageModel message) => insertMessageIntoDb(message);
  Future<void> saveUser(UserModel user) => insertUserIntoDb(user);

  Future<List<ChatModel>?> getChats() => loadAllChats().then((chats) => chats.isEmpty ? null : chats);
  Future<List<MessageModel>?> getMessages(int chatId) => loadMessagesForChat(chatId).then((msgs) => msgs.isEmpty ? null : msgs);
  Future<void> deleteMessage(int messageId, int chatId) async {
    // Could be implemented
  }
  Future<void> deleteChat(int chatId) async {
    // Could be implemented
  }
}
