import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_logic/chat_provider.dart';
import 'package:hazelnut_shared/navigation.dart';
import 'package:hazelnut_ui/snackbar_utils.dart';
import 'package:hazelnut_ui/theme.dart';

class JoinChatModal extends ConsumerStatefulWidget {
  const JoinChatModal({super.key});

  @override
  ConsumerState<JoinChatModal> createState() => _JoinChatModalState();
}

class _JoinChatModalState extends ConsumerState<JoinChatModal> {
  bool showingError = false;

  final FocusNode chatNameFocusNode = FocusNode();
  final FocusNode chatAuthFocusNode = FocusNode();

  final TextEditingController chatNameController = TextEditingController();
  final TextEditingController chatAuthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(chatProviderProvider).loadChats();
  }

  @override
  void dispose() {
    chatNameController.dispose();
    chatAuthController.dispose();
    chatNameFocusNode.dispose();
    chatAuthFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 50),
      color: theme.neutral.shade700,
      child: IntrinsicHeight(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  focusNode: chatNameFocusNode,
                  controller: chatNameController,
                  style: TextStyle(color: Colors.white, fontFamily: "IBM Sans", fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.neutral.shade500,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    icon: Icon(Icons.tag_rounded, color: theme.info.shade400)
                  ),
                  cursorColor: Colors.white,
                  onTapOutside: (event) {
                    chatNameFocusNode.unfocus();
                  },
                ),
                SizedBox(height: 20),
                TextField(
                  focusNode: chatAuthFocusNode,
                  controller: chatAuthController,
                  style: TextStyle(color: Colors.white, fontFamily: "IBM Sans", fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.neutral.shade500,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    icon: Icon(Icons.key_rounded, color: theme.info.shade400)
                  ),
                  cursorColor: Colors.white,
                  onTapOutside: (event) {
                    chatAuthFocusNode.unfocus();
                  },
                ),
              ],
            ),
            SizedBox(height: 80),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async { await addChat(theme); },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(theme.neutral.shade500),
                      shape:           WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                      shadowColor:     WidgetStatePropertyAll(Colors.transparent),
                      overlayColor:    WidgetStateProperty.resolveWith<Color?>(
                                        (Set<WidgetState> states) {
                                          if (states.contains(WidgetState.pressed)) {
                                            return theme.neutral.shade200!.withValues(alpha: 100);
                                          }
                                          return null;
                                        },
                      ),
                    ),
                    child: Text("Chat beitreten", style: TextStyle(color: theme.info.shade400, fontFamily: "IBM Sans", fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addChat(CustomColors theme) async {
    if (chatNameController.text == "") {
      showAnimatedSnackbarGlobal(
        navigatorKey: await ref.read(navigatorKeyProvider),
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
        navigatorKey: ref.read(navigatorKeyProvider),
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
      await ref.read(appDependenciesProvider).webSocketService.sendMessage(jsonEncode(request).toString());
  }
}