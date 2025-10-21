import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hazelnut/components/chat_list.dart';
import 'package:hazelnut/utils/database_service.dart';
import 'package:hazelnut/utils/local_notifications.dart';
import 'package:hazelnut/utils/preferences_utils.dart';
import 'package:hazelnut/utils/secure_storage_service.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/models.dart';
import 'package:hazelnut/utils/websocket_service.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/message_provider.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SecureStorageService secureStorage = SecureStorageService();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await MessageProvider().loadAll();
      ChatNotifications().cancelChatNotifications(widget.chatId, true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() async => await MessageProvider().loadAll());
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {
      "header": "new_message",
      "body": {
        "uId":           await getInt("lastUId"),
        "pending":       1,
        "authToken":     await secureStorage.getToken("authToken"),
        "chatId":        widget.chatId,
        "text":          text.toString(),
        "senderId":      await secureStorage.getToken("userId"),
        "senderName":    await secureStorage.getToken("username"),
        "sentTimestamp": DateTime.now().toUtc().toIso8601String(),
      }
    };

    final messageForDb = (message["body"] as Map<String, dynamic>);
    messageForDb.remove("authToken");
    messageForDb["messageId"] = await DatabaseService().getLatestMessageId();

    WebSocketService().sendMessage(jsonEncode(message));
    MessageProvider().addMessage(MessageModel.fromJson(messageForDb));

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    final List<ChatModel>  chats  = ChatProvider().chats;
    final ChatModel        chat   = chats[widget.chatId];

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: theme.background.shade800,
            child: Column(
              children: [
                Expanded(
                  child: ChatList(chatId: widget.chatId),
                ),
                SizedBox(
                  height: 65,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 10, right: 10, bottom: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: BoxBorder.all(color: theme.background.shade600!, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  decoration: InputDecoration(
                                    hintText: "Nachricht schreiben...",
                                    hintStyle: TextStyle(color: Theme.of(context).primaryColor.withAlpha(120), fontSize: 15),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 15),
                                  cursorColor: Theme.of(context).primaryColor,
                                  maxLines: 1,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.send_rounded),
                                onPressed: _sendMessage,
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                color: theme.background.shade600,
                child: SafeArea(
                  top: true,
                  left: false,
                  right: false,
                  bottom: true,
                  child: Container(),
                ),
              ),
              Container(
                height: 55,
                width: double.infinity,
                color: theme.background.shade600,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ChatNotifications().setCurrentChatId(null);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        color: Colors.transparent,
                        width: 50,
                        height: 50,
                        margin: EdgeInsets.only(left: 15),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(left: 20),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.background.shade300,
                                child: Text(
                                  chat.chatName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF6A760C),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
                                height: 40,
                                child: Row(
                                  children: [
                                    Center(
                                      child: Text(
                                        chat.chatName,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor.withAlpha(240),
                                          fontFamily: "Space Grotesk",
                                          fontSize: 17,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}