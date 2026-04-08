import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hazelnut/components/chat_list.dart';
import 'package:hazelnut/utils.dart';
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

    final safeMessage = sanitizeRawInput(text, maxLength: 65536);

    final message = {
      "header": "new_message",
      "body": {
        "uId":           await PreferencesUtils().getInt("lastUId") ?? 0,
        "pending":       1,
        "chatId":        widget.chatId,
        "text":          safeMessage.toString(),
        "senderId":      await secureStorage.getToken("userId"),
        "senderName":    await secureStorage.getToken("username"),
        "sentTimestamp": DateTime.now().toUtc().toIso8601String(),
      }
    };

    final messageForDb = (message["body"] as Map<String, dynamic>);
    messageForDb.remove("authToken");
    messageForDb["messageId"] = await DatabaseService().getLatestMessageId();

    WebSocketService().sendMessage(jsonEncode(message));
    MessageProvider().addMessage(MessageModel.fromJson(messageForDb), true);

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
                color: theme.background.shade700,
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
                color: theme.background.shade700,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
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
                                    color: getAccentFromString(chat.chatName),
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
                            Container(
                              margin: EdgeInsets.only(right: 10),
                              child: Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(Icons.menu),
                                  padding: EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
                                  color: Theme.of(context).primaryColor,
                                  onPressed: () => Scaffold.of(context).openDrawer(),
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

      drawer: SafeArea(
        child: Drawer(
          backgroundColor: theme.background.shade700,
          child: FutureBuilder(
            future: DatabaseService().getUsersForChat(widget.chatId),
            builder: (context, asyncSnapshot) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(top: 15),
                    color: theme.background.shade600,
                    height: 55,
                    child: Text(
                      "Nutzer im Chat",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor.withAlpha(200),
                        fontFamily: "Space Grotesk",
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: asyncSnapshot.data?.isEmpty ?? true ? 
                    
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.not_accessible_rounded),
                        Text(
                          "Du bist der einzige hier",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor.withAlpha(150),
                            fontFamily: "Space Grotesk",
                            fontSize: 15,
                          ),
                        ),
                      ],
                    )

                    :
                    
                    ListView.builder(
                      itemCount: asyncSnapshot.data?.length ?? 0,
                      itemBuilder: (context, index) {
                        return Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(top: 5, bottom: 5, left: 15, right: 10),
                          height: 50,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      asyncSnapshot.data?[index].username ?? "Unbekannt",
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor.withAlpha(200),
                                        fontFamily: "Space Grotesk",
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      asyncSnapshot.data?[index].online ?? false ? "Online" : "Offline",
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor.withAlpha(150),
                                        fontFamily: "Space Grotesk",
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  final joinedDate = DateTime.parse(asyncSnapshot.data?[index].joinedTimestamp ?? DateTime.now().toIso8601String());
                                  
                                  showMenu<String>(
                                    context: context,
                                    position: RelativeRect.fromLTRB(100, 100, 0, 0), // x, y Koordinaten
                                    items: [
                                      PopupMenuItem(
                                        child: RichText(
                                          text: TextSpan(
                                            text: "Username:  ",
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor.withAlpha(200),
                                              fontFamily: "Space Grotesk",
                                              fontSize: 14,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: asyncSnapshot.data?[index].username,
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor.withAlpha(200),
                                                  fontFamily: "Space Grotesk",
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ]
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        child: RichText(
                                          text: TextSpan(
                                            text: "User-ID:  ",
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor.withAlpha(200),
                                              fontFamily: "Space Grotesk",
                                              fontSize: 14,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: asyncSnapshot.data?[index].userId,
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor.withAlpha(200),
                                                  fontFamily: "Space Grotesk",
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ]
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(child: Flexible(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor.withAlpha(200),
                                              fontFamily: "Space Grotesk",
                                              fontSize: 14,
                                            ),
                                            text: "Beigetreten am:",
                                            children: [
                                              TextSpan(
                                                text: " ${joinedDate.day.toString().padLeft(2, '0')}.${joinedDate.month.toString().padLeft(2, '0')}.${joinedDate.year}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: " um ",
                                              ),
                                              TextSpan(
                                                text: "${joinedDate.hour.toString().padLeft(2, '0')}:${joinedDate.minute.toString().padLeft(2, '0')}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      )),
                                      PopupMenuItem(
                                        child: RichText(
                                          text: TextSpan(
                                            text: "Online:  ",
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor.withAlpha(200),
                                              fontFamily: "Space Grotesk",
                                              fontSize: 14,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: asyncSnapshot.data?[index].online ?? false ? "Ja" : "Nein",
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor.withAlpha(200),
                                                  fontFamily: "Space Grotesk",
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ]
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                child: SizedBox(
                                  width: 50,
                                  height: double.infinity,
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: Theme.of(context).primaryColor.withAlpha(200),
                                  )
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}