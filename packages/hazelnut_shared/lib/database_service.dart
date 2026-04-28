import 'package:hazelnut_shared/models.dart';

abstract class DatabaseService {
  Future<void> insertChatIntoDb(ChatModel chat);
  Future<void> insertMessageIntoDb(MessageModel message);
  Future<void> insertUserIntoDb(UserModel user);

  Future<void> addUserToChat(int chatId, UserModel user);
  Future<List<UserModel>> getUsersForChat(int chatId);

  Future<List<ChatModel>> loadAllChats();
  Future<List<MessageModel>> loadMessagesForChat(int chatId);

  Future<List<MessageModel>?> getPendingMessages();
  Future<int> getLatestMessageId();

  Future<List<UserModel>> loadAllUsers();
  void clearAll();
}