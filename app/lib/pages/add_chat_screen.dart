import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/secure_storage_service.dart';

import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/snackbar_utils.dart';
import 'package:hazelnut/utils/websocket_service.dart';

class AddChatScreen extends StatefulWidget {
  AddChatScreen({super.key});

  @override
  State<AddChatScreen> createState() => _AddChatScreenState();
}

class _AddChatScreenState extends State<AddChatScreen> {
  final SecureStorageService secureStorage = SecureStorageService();
  bool showingError = false;

  final FocusNode chatNameFocusNode = FocusNode();
  final FocusNode chatAuthFocusNode = FocusNode();

  final TextEditingController chatNameController = TextEditingController();
  final TextEditingController chatAuthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async => await ChatProvider().loadChats());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() async => await ChatProvider().loadChats());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      backgroundColor: theme.background.shade800,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: SafeArea(
        top: true,
        left: false,
        right: false,
        bottom: true,
        child: Container(
          color: theme.background.shade700,
          child: Align(
            alignment: Alignment(0, -0.35),
            child: Container(
              color: Colors.transparent,
              height: MediaQuery.of(context).size.height.toInt() * 0.45,
              width: MediaQuery.of(context).size.width.toInt() * 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Chatroom-Name:", style: TextStyle(color: Theme.of(context).primaryColor, fontFamily: "Space Grotesk")),
                      SizedBox(height: 5),
                      TextField(
                        focusNode: chatNameFocusNode,
                        controller: chatNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.background.shade500,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onTapOutside: (event) {
                          chatNameFocusNode.unfocus();
                        },
                      ),
                      SizedBox(height: 50),
                      Text("Chatroom-Passwort:", style: TextStyle(color: Theme.of(context).primaryColor, fontFamily: "Space Grotesk")),
                      SizedBox(height: 5),
                      TextField(
                        focusNode: chatAuthFocusNode,
                        controller: chatAuthController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.background.shade500,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none
                          ),
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onTapOutside: (event) {
                          chatAuthFocusNode.unfocus();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                          if (chatNameController.text == "") {
                            showAnimatedSnackbarGlobal(
                              color1: theme.info.shade500!,
                              color2: theme.info.shade400!,
                              icon: Icons.error_outline_rounded,
                              title: "Chatroom-Name ist nicht gesetzt!",
                              heightOffset: 50,
                            );
                            return;
                          }
    
                          if (chatAuthController.text == "") {
                            showAnimatedSnackbarGlobal(
                              color1: theme.info.shade500!,
                              color2: theme.info.shade400!,
                              icon: Icons.error_outline_rounded,
                              title: "Chatroom-Passwort ist nicht gesetzt!",
                              heightOffset: 50,
                            );
                            return;
                          }

                            final String chatName  = chatNameController.text.toString();
                            final String chatAuth  = chatAuthController.text.toString();
                            final String timestamp = DateTime.now().toUtc().toIso8601String();

                            Map<String, dynamic> request = {
                              "header": "join_chat",
                              "body": {
                                "chatName":  chatName,
                                "chatAuth":  chatAuth,
                                "timestamp": timestamp
                              }
                            };

                            if (!context.mounted) return;
                            webSocketService().sendMessage(jsonEncode(request).toString());
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(theme.background.shade600),
                            shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            ),
                            overlayColor: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return theme.background.shade200!.withValues(alpha: 100);
                                }
                                return null;
                              },
                            ),
                          ),
                          child: Text("Verbinden", style: TextStyle(color: theme.info.shade500)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.background.shade600,
        title: Text(
          "Neuen Chat hinzufügen",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontFamily: "Space Grotesk",
            fontSize: 21,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}