import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/pages/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatNotifications {
  ChatNotifications._internal();
  static final ChatNotifications _instance = ChatNotifications._internal();
  factory ChatNotifications() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int? currentChatId;

  final Map<int, int> _newMessageCount = {};

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);
    _initialized = true;

    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("User tapped a notification: ${message.data}");

      navigatorKey.currentState?.push(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(chatId: int.parse(message.data["chatId"])),
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
    });
  }

  void _handleMessage(RemoteMessage message, {FlutterLocalNotificationsPlugin? plugin}) async {
    final usedPlugin = plugin ?? _localNotifications;

    debugPrint("Message received: ${message.data}");
    final data = message.data;

    if (data["type"] != "new_message") {
      debugPrint("Not a new message notification, ignoring.");
      return;
    }

    if (data["chatName"] == null || data["chatId"] == null) return;

    final chatId = int.tryParse(data["chatId"].toString());
    if (chatId == null) return;

    if (currentChatId != null && chatId == currentChatId) {
      debugPrint("Message received in current chat, not showing notification.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = "chat_$chatId";
    final prevCount = prefs.getInt(key) ?? 0;
    final newCount = prevCount + 1;
    await prefs.setInt(key, newCount);

    _newMessageCount[chatId] = newCount;

    cancelChatNotifications(chatId, false);

    usedPlugin.show(
      chatId, // ID = ChatId
      data["title"] ?? "Neue Nachricht",
      "Du hast $newCount neue Nachricht${newCount > 1 ? "en" : ""} in ${message.data["chatName"]}",
      NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'Standard',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/notification_icon',
        ),
      ),
    );
  }

  Future<void> updateCache(int chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final key = "chat_$chatId";
    final count = prefs.getInt(key) ?? 0;
    _newMessageCount[chatId] = count;
  }

  Future<void> cancelChatNotifications(int chatId, bool resetCounter) async {
    await _localNotifications.cancel(chatId);
    if (!resetCounter) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("chat_$chatId", 0);

    _newMessageCount[chatId] = 0;
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    _newMessageCount.clear();
  }

  void setCurrentChatId(int? chatId) {
    currentChatId = chatId;
  }
}
