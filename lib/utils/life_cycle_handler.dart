import 'package:flutter/material.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/local_notifications.dart';

class MyAppLifecycleHandler extends StatefulWidget {
  final Widget child;
  const MyAppLifecycleHandler({super.key, required this.child});

  @override
  State<MyAppLifecycleHandler> createState() => _MyAppLifecycleHandlerState();
}

class _MyAppLifecycleHandlerState extends State<MyAppLifecycleHandler> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      for (var chat in ChatProvider().chats) {
        ChatNotifications().updateCache(chat.chatId);
      }

      debugPrint("App resumed, updated Notifications-Cache");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}