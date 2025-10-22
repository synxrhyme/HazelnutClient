import 'package:hazelnut/main.dart';
import 'package:flutter/material.dart';
import 'package:hazelnut/pages/setup_page.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/database_service.dart';
import 'package:hazelnut/utils/message_provider.dart';
import 'package:hazelnut/utils/preferences_utils.dart';
import 'package:hazelnut/utils/websocket_service.dart';

void signout() async {
  secureStorage.deleteToken("username");
  secureStorage.deleteToken("userId");

  secureStorage.deleteToken("authToken");
  secureStorage.deleteToken("refreshToken");

  await PreferencesUtils().setBool("setupComplete", false);

  navigatorKey.currentState?.push(
    PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 500),
      settings: RouteSettings(name: "setupPage"),
      pageBuilder: (context, animation, secondaryAnimation) => SetupPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    )
  );

  WebSocketService().setReady(false);
  DatabaseService().clearAll();

  ChatProvider().loadChats();
  MessageProvider().loadAll();
}