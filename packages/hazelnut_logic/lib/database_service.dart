import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hazelnut_shared/database_service.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_shared/preferences_service.dart';

class DatabaseServiceImpl extends DatabaseService {
  final Database chatDb;
  final Database messageDb;
  final Database userDb;
  final PreferencesService preferences;

  DatabaseServiceImpl._(
    this.chatDb,
    this.messageDb,
    this.userDb,
    this.preferences,
  );

  static Future<DatabaseServiceImpl> create({
    required PreferencesService preferences,
  }) async {
    final chatDb = await _initChatDB();
    final messageDb = await _initMessageDB();
    final userDb = await _initUserDB();

    return DatabaseServiceImpl._(
      chatDb,
      messageDb,
      userDb,
      preferences,
    );
  }

  static Future<Database> _initChatDB() async {
    final path = join(await getDatabasesPath(), 'chat.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE chats("
            "chatId INTEGER PRIMARY KEY,"
            "chatName TEXT,"
            "chatAuth TEXT,"
            "createdById TEXT,"
            "createdByName TEXT,"
            "createdTimestamp TEXT"
          ")",
        );

        await db.execute(
          "CREATE TABLE chat_users("
            "chatId INTEGER,"
            "userId TEXT,"
            "PRIMARY KEY (chatId, userId)"
          ")",
        );
      },
    );
  }

  static Future<Database> _initMessageDB() async {
    final path = join(await getDatabasesPath(), 'msg.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE messages("
            "uId INTEGER PRIMARY KEY,"
            "messageId INTEGER,"
            "pending INTEGER,"
            "chatId INTEGER,"
            "senderId TEXT,"
            "senderName TEXT,"
            "text TEXT,"
            "sentTimestamp TEXT,"
            "receivedTimestamp TEXT"
          ")",
        );
      },
    );
  }

  static Future<Database> _initUserDB() async {
    final path = join(await getDatabasesPath(), 'user.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE users("
            "userId TEXT PRIMARY KEY,"
            "username TEXT,"
            "joinedTimestamp TEXT,"
            "lastSeen TEXT"
          ")",
        );
      },
    );
  }

  @override
  Future<void> insertChatIntoDb(ChatModel chat) async {
    await chatDb.insert('chats', chat.exportJson());
  }

  @override
  Future<void> insertMessageIntoDb(MessageModel message) async {
    final int lastUId = (await preferences.getInt("lastUId")) ?? 0;
    await preferences.setInt("lastUId", lastUId + 1);
    await messageDb.insert('messages', message.exportJson());
  }

  @override
  Future<void> insertUserIntoDb(UserModel user) async {
    await userDb.insert('users', user.exportJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> addUserToChat(int chatId, UserModel user) async {
    await insertUserIntoDb(user);
    await chatDb.insert(
      'chat_users',
      {'chatId': chatId, 'userId': user.userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<UserModel>> getUsersForChat(int chatId) async {
    final List<Map<String, dynamic>> mappings = await chatDb.query(
      'chat_users',
      where: 'chatId = ?',
      whereArgs: [chatId],
    );

    final List<UserModel> users = [];
    for (final m in mappings) {
      final List<Map<String, dynamic>> rows = await userDb.query(
        'users',
        where: 'userId = ?',
        whereArgs: [m['userId']],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        users.add(UserModel.fromJson(rows.first));
      }
    }
    return users;
  }

  @override
  Future<List<ChatModel>> loadAllChats() async {
    final List<Map<String, dynamic>> maps = await chatDb.query("chats");
    return List<ChatModel>.generate(maps.length, (index) {
      return ChatModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<MessageModel>> loadMessagesForChat(int chatId) async {
    final List<Map<String, dynamic>> mappedMessages = await messageDb.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
    );

    return List<MessageModel>.generate(mappedMessages.length, (index) {
      return MessageModel.fromJson(mappedMessages[index]);
    });
  }

  @override
  Future<int> getLatestMessageId() async {
    final result = await messageDb.query(
      'messages',
      orderBy: 'messageId DESC',
    );

    final latestId = result.isNotEmpty ? result.first['messageId'] as int : 0;
    return latestId;
  }

  @override
  Future<List<UserModel>> loadAllUsers() async {
    final List<Map<String, dynamic>> maps = await userDb.query('users');
    
    return List<UserModel>.generate(maps.length, (i) {
      return UserModel.fromJson(maps[i]);
    });
  }

  @override
  Future<List<MessageModel>?> getPendingMessages() async {
    final List<Map<String, dynamic>> mappedMessages = await messageDb.query(
      'messages',
      where: 'pending = ?',
      whereArgs: [1],
    );

    if (mappedMessages.isEmpty) return null;

    return List<MessageModel>.generate(mappedMessages.length, (index) {
      return MessageModel.fromJson(mappedMessages[index]);
    });
  }

  @override
  void clearAll() async {
    await chatDb.delete("chats");
    await chatDb.delete("chat_users");
    await messageDb.delete("messages");
    await userDb.delete("users");
  }
}