class ChatModel {
  final int    chatId;
  final String chatName;
  final String chatAuth;
  final String createdById;
  final String createdByName;
  final String createdTimestamp;
  List<UserModel> users = [];

  ChatModel({
    required this.chatId,
    required this.chatName,
    required this.chatAuth,
    required this.createdById,
    required this.createdByName,
    required this.createdTimestamp,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId:            json["chatId"],
      chatName:          json["chatName"],
      chatAuth:          json["chatAuth"],
      createdById:       json["createdById"],
      createdByName:     json["createdByName"],
      createdTimestamp:  json["createdTimestamp"],
    );
  }

  Map<String, dynamic> exportJson() {
    return {
      "chatId":           chatId,
      "chatName":         chatName,
      "chatAuth":         chatAuth,
      "createdById":      createdById,
      "createdByName":    createdByName,
      "createdTimestamp": createdTimestamp,
    };
  }

  void addUser(UserModel user) {
    users.add(user);
  }
}

class MessageModel {
  final int uId;
  int messageId;
  final int chatId;
  final String senderId;
  final String senderName;
  final String text;
  final String sentTimestamp;
  final String receivedTimestamp;
  
  int pending = 1;

  MessageModel({
    required this.uId,
    required this.messageId,
    required this.chatId,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.sentTimestamp,
    required this.receivedTimestamp,
    required this.pending,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      uId:               json["uId"],
      messageId:         json["messageId"],
      pending:           json["pending"],
      chatId:            json["chatId"],
      text:              json["text"],
      senderId:          json["senderId"],
      senderName:        json["senderName"],
      sentTimestamp:     json["sentTimestamp"],
      receivedTimestamp: "",
    );
  }

  Map<String, dynamic> exportJson() {
    return {
      "uId":               uId,
      "messageId":         messageId,
      "pending":           pending,
      "chatId":            chatId,
      "senderId":          senderId,
      "senderName":        senderName,
      "text":              text,
      "sentTimestamp":     sentTimestamp,
      "receivedTimestamp": receivedTimestamp,
    };
  }
}

class UserModel {
  final String userId;
  final String username;
  final String joinedTimestamp;
  final String lastSeen;
  bool online;

  UserModel({
    required this.userId,
    required this.username,
    required this.joinedTimestamp,
    required this.lastSeen,
    this.online = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId:           json["userId"],
      username:         json["username"],
      joinedTimestamp:  json["joinedTimestamp"],
      lastSeen:         json["lastSeen"],
      online:           json["online"] ?? false,
    );
  }

  Map<String, dynamic> exportJson() {
    return {
      "userId":           userId,
      "username":         username,
      "joinedTimestamp":  joinedTimestamp,
      "lastSeen":         lastSeen,
    };
  }
}