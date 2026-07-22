import 'package:gradient_opacity_mask/gradient_opacity_mask.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_logic/chat_provider.dart';
import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/message_provider.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/util.dart';
import 'package:hazelnut_logic/websocket_service.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_ui/components/message_list.dart';
import 'package:hazelnut_ui/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  late final SecureStorageService secureStorage;
  late final PreferencesService preferencesService;
  late final DatabaseService databaseService;
  late final WebSocketService webSocketService;
  late final MessageProvider messageProvider;
  late final ChatProvider chatProvider;

  @override
  void initState() {
    super.initState();
    secureStorage = ref.watch(appDependenciesProvider).secureStorageService;
    preferencesService = ref.watch(appDependenciesProvider).prefsService;
    databaseService = ref.watch(appDependenciesProvider).databaseService;
    webSocketService = ref.watch(appDependenciesProvider).webSocketService;

    messageProvider = ref.watch(messageProviderProvider);
    chatProvider = ref.watch(chatProviderProvider);

    Future.microtask(() async {
      await messageProvider.loadAll();
      //ChatNotifications().cancelChatNotifications(widget.chatId, true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() async => await messageProvider.loadAll());
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final safeMessage = sanitizeRawInput(text, maxLength: 65536);

    final message = {
      "header": "new_message",
      "body": {
        "uId":           await preferencesService.getInt("lastUId") ?? 0,
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
    messageForDb["messageId"] = await databaseService.getLatestMessageId();

    webSocketService.sendMessage(jsonEncode(message));
    messageProvider.addMessage(MessageModel.fromJson(messageForDb), true);

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;
    final FocusNode focusNode = FocusNode();

    final List<ChatModel>  chats  = chatProvider.chats;
    final ChatModel        chat   = chats[widget.chatId];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.neutral.shade700,
        leading: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: theme.neutral.shade300,
                child: Text(
                  chat.chatName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: "Space Grotesk",
                    fontWeight: FontWeight.w800,
                    color: getAccentFromString(chat.chatName),
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
                            color: Colors.white,
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
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  padding: EdgeInsets.only(right: 10, left: 10, top: 10, bottom: 10),
                  color: Colors.white,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: MessageList(chatId: widget.chatId)),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.neutral.shade800!,
                      theme.neutral.shade600!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                height: 70,
                width: double.infinity
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: "Nachricht schreiben...",
                                hintStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 15),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(color: Colors.white, fontSize: 15),
                              cursorColor: Colors.white,
                              maxLines: 1,
                              onTapOutside: (event) {
                                focusNode.unfocus();
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send_rounded),
                            onPressed: _sendMessage,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      endDrawerEnableOpenDragGesture: false,
      drawer: Drawer(
        backgroundColor: theme.neutral.shade600,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          top: true,
          bottom: true,
          child: FutureBuilder(
            future: databaseService.getUsersForChat(widget.chatId),
            builder: (context, asyncSnapshot) {
              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Text(
                      "Nutzer im Chat",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.accent.shade400,
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
                        Icon(Icons.person_off_rounded, color: Colors.white, size: 40),
                        SizedBox(height: 15),
                        Text(
                          "Du bist der einzige hier",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Space Grotesk",
                            fontSize: 15,
                          ),
                        ),
                      ],
                    )
                
                    :
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListView.builder(
                        itemCount: asyncSnapshot.data?.length ?? 0,
                        itemBuilder: (context, index) {
                          return Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.neutral.shade300,
                                  child: Text(
                                    asyncSnapshot.data?[index].username[0].toUpperCase() ?? "U",
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontFamily: "Space Grotesk",
                                      fontWeight: FontWeight.w800,
                                      color: getAccentFromString(chat.chatName),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asyncSnapshot.data?[index].username ?? "Unbekannt",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "Space Grotesk",
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        asyncSnapshot.data?[index].online ?? false ? "Online" : "Offline",
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(200),
                                          fontFamily: "Space Grotesk",
                                          fontSize: 10,
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
                                                color: Colors.white,
                                                fontFamily: "Space Grotesk",
                                                fontSize: 14,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: asyncSnapshot.data?[index].username,
                                                  style: TextStyle(
                                                    color: Colors.white,
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
                                                color: Colors.white,
                                                fontFamily: "Space Grotesk",
                                                fontSize: 14,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: asyncSnapshot.data?[index].userId,
                                                  style: TextStyle(
                                                    color: Colors.white,
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
                                                color: Colors.white,
                                                fontFamily: "Space Grotesk",
                                                fontSize: 14,
                                              ),
                                              text: "Beigetreten am:",
                                              children: [
                                                TextSpan(
                                                  text: " ${joinedDate.day.toString().padLeft(2, '0')}.${joinedDate.month.toString().padLeft(2, '0')}.${joinedDate.year}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: " um ",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: "${joinedDate.hour.toString().padLeft(2, '0')}:${joinedDate.minute.toString().padLeft(2, '0')}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
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
                                                color: Colors.white,
                                                fontFamily: "Space Grotesk",
                                                fontSize: 14,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: asyncSnapshot.data?[index].online ?? false ? "Ja" : "Nein",
                                                  style: TextStyle(
                                                    color: Colors.white,
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
                                      color: Colors.white.withAlpha(200),
                                    )
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
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