import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/utils/loading_provider.dart';
import 'package:hazelnut/utils/snackbar_utils.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/websocket_service.dart';

class MainPage2 extends ConsumerStatefulWidget {
  const MainPage2({super.key});

  @override
  ConsumerState<MainPage2> createState() => _MainPage2State();
}

class _MainPage2State extends ConsumerState<MainPage2> {
  final FocusNode chatNameFocusNode = FocusNode();
  final FocusNode chatAuthFocusNode = FocusNode();

  final TextEditingController chatNameController = TextEditingController();
  final TextEditingController chatAuthController = TextEditingController();

  bool showingError = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.only(top: 70),
            child: Text('Chatrooms erstellen', style: TextStyle(fontSize: 24, fontFamily: "Space Grotesk", color: Theme.of(context).primaryColor), textAlign: TextAlign.center),
          ),
          Container(
            margin: EdgeInsets.only(top: 50),
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withAlpha(30),
              borderRadius: BorderRadius.circular(7)
            ),
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                        fillColor: Colors.grey.shade800.withAlpha(40),
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
                        fillColor: Colors.grey.shade800.withAlpha(40),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (chatNameController.text == "") {
                            showAnimatedSnackbarGlobal(
                              icon: Icons.error_outline_rounded,
                              color1: theme.info.shade500!,
                              color2: theme.info.shade400!,
                              title: "Chatroom-Name ist nicht gesetzt!",
                              heightOffset: 50,
                            );
                            return;
                          }
    
                          if (chatAuthController.text == "") {
                            showAnimatedSnackbarGlobal(
                              icon: Icons.error_outline_rounded,
                              color1: theme.info.shade500!,
                              color2: theme.info.shade400!,
                              title: "Chatroom-Passwort ist nicht gesetzt!",
                              heightOffset: 50,
                            );
                            return;
                          }

                          ref.read(loadingServiceProvider).show();
                          await Future.delayed(Duration.zero);
    
                          final String userId    = await secureStorage.getToken("userId");
                          final String chatName  = chatNameController.text.toString();
                          final String chatAuth  = chatAuthController.text.toString();
                          final String timestamp = DateTime.now().toUtc().toIso8601String();
    
                          Map<String, dynamic> request = {
                            "header": "create_chat",
                            "body": {
                              "userId":    userId,
                              "chatName":  chatName,
                              "chatAuth":  chatAuth,
                              "timestamp": timestamp
                            }
                          };
    
                          if (!context.mounted) return;
                          WebSocketService().sendMessage(jsonEncode(request).toString());

                          chatNameController.clear();
                          chatAuthController.clear();
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.grey.shade800.withAlpha(50)),
                          shape:           WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                          shadowColor:     WidgetStatePropertyAll(Colors.transparent),
                          overlayColor:    WidgetStateProperty.resolveWith<Color?>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.pressed)) {
                                                return theme.background.shade200!.withValues(alpha: 100);
                                              }
                                              return null;
                                            },
                          ),
                        ),
                        child: Text("Chatroom erstellen", style: TextStyle(color: theme.info.shade500)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}