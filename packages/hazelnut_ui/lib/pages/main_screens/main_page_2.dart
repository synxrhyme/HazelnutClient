import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_shared/navigation.dart';
import 'package:hazelnut_logic/loading_provider.dart';
import 'package:hazelnut_ui/components/standard_app_bar.dart';
import 'package:hazelnut_ui/snackbar_utils.dart';
import 'package:hazelnut_ui/theme.dart';

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
  void dispose() {
    chatNameFocusNode.dispose();
    chatAuthFocusNode.dispose();
    chatNameController.dispose();
    chatAuthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: StandardAppBar(theme: theme, title: "Chatrooms erstellen", leading: null),
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: AlignmentGeometry.xy(0, -0.4),
        child: Container(
          margin: EdgeInsets.only(top: 50),
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: theme.neutral.shade600,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(height: 50),
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
                      cursorColor: theme.info.shade400,
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
                          borderRadius: BorderRadius.circular(15)
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
                      cursorColor: theme.info.shade400,
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
                        onPressed: () async {
                          await createChatRoom(theme);
                        },
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
                        child: Text("Chatroom erstellen", style: TextStyle(color: theme.info.shade400, fontFamily: "IBM Sans", fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> createChatRoom(CustomColors theme) async {
    if (chatNameController.text == "") {
        showAnimatedSnackbarGlobal(
          navigatorKey: ref.read(navigatorKeyProvider),
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
          navigatorKey: ref.read(navigatorKeyProvider),
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
      
      final String chatName  = chatNameController.text.toString();
      final String chatAuth  = chatAuthController.text.toString();
      final String timestamp = DateTime.now().toUtc().toIso8601String();
      
      Map<String, dynamic> request = {
        "header": "create_chat",
        "body": {
          "chatName":  chatName,
          "chatAuth":  chatAuth,
          "timestamp": timestamp
        }
      };
      
      if (!context.mounted) return;
      ref.read(appDependenciesProvider).webSocketService.sendMessage(jsonEncode(request).toString());
      
      chatNameController.clear();
      chatAuthController.clear();
  }
}