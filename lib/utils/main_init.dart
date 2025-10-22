import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/pages/home_page.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/database_service.dart';
import 'package:hazelnut/utils/loading_provider.dart';
import 'package:hazelnut/utils/local_notifications.dart';
import 'package:hazelnut/utils/message_provider.dart';
import 'package:hazelnut/utils/models.dart';
import 'package:hazelnut/utils/preferences_utils.dart';
import 'package:hazelnut/utils/secure_storage_service.dart';
import 'package:hazelnut/utils/snackbar_utils.dart';
import 'package:hazelnut/utils/websocket_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (message.data["chatName"] == null || message.data["chatId"] == null) return;
  debugPrint("handling background");

  final int chatId = int.parse(message.data["chatId"]);
  
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await PreferencesUtils().init();
  await PreferencesUtils().reload();
  final String key = "chat_$chatId";

  final int? prevCount = await PreferencesUtils().getInt(key);
  if (prevCount == null) {
    debugPrint("First notification for chat $chatId, setting count to 1");
    return;
  }

  final int newCount = prevCount + 1;
  await PreferencesUtils().setInt(key, newCount);

  await flutterLocalNotificationsPlugin.show(
    chatId,
    message.data["title"] ?? "Neue Nachricht",
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

Future<void> initFirebase(SecureStorageService secureStorage) async {
  unawaited(Firebase.initializeApp().then((_) async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    messaging.subscribeToTopic("HazelnutMessenger");

    final String savedToken = await secureStorage.getToken("fcmToken");

    if (savedToken.isEmpty) {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final String fcmToken = await messaging.getToken() ?? "";
      if (fcmToken.isNotEmpty) {
        await secureStorage.saveToken("fcmToken", fcmToken);
      }
    }

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
  }));
}

Future<void> initFullServices(SecureStorageService secureStorage) async {
  await ChatNotifications().init();

  WebSocketService().setUrl("wss://hazelnut.synxrhyme.com/ws/");
  await WebSocketService().connect();
  WebSocketService().onMessage = onMessage;
}

void onMessage(Map<String, dynamic> data, WidgetRef ref) async {
  debugPrint(data.toString());
  
  switch (data["header"]) {
    case "registration_response": {
      switch (data["status"]) {
        case "success": {
          await secureStorage.saveToken("userId",       data["body"]["userId"].toString());
          await secureStorage.saveToken("username",     data["body"]["username"].toString());
          await secureStorage.saveToken("fcmToken",     data["body"]["fcmToken"].toString());

          await secureStorage.saveToken("authToken",    data["body"]["authToken"].toString());
          await secureStorage.saveToken("refreshToken", data["body"]["refreshToken"].toString());

          await PreferencesUtils().setBool("setupComplete", true);

          navigatorKey.currentState?.push(
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 500),
              settings: RouteSettings(name: "homePage"),
              pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0); // Start rechts außerhalb des Bildschirms
                const end = Offset.zero;        // Ende an der normalen Position
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

          break;
        }

        case "username_taken": {
          showSnackBar("Username schon vergeben!", 0);
          break;
        }

        case "app_already_registered": {
          showSnackBar("Diese App wurde\nschon registriert??", 0);
          break;
        }
      }

      ref.read(loadingServiceProvider).hide();
      break;
    }

    case "chat_creation_response": {
      switch (data["status_code"]) {
        case 0: showSnackBar("Chatname schon vergeben", 0);
        case 1: showSnackBar("Chaterstellung erfolgreich", 2);
      }

      ref.read(loadingServiceProvider).hide();
      break;
    }

    case "join_response": {
      debugPrint(data.toString());
      
      switch (data["status_code"]) {
        case 0: showSnackBar("Kein Chatroom gefunden", 0);
        case 1: showSnackBar("Falsches Passwort", 0);
        case 2: showSnackBar("Du bist bereits Mitglied", 1);
        case 3: {
          final ChatModel chatModel = ChatModel.fromJson(data["body"]);
          ChatProvider().addChat(chatModel);

          showSnackBar("Erfolgreich beigetreten", 2);
          ref.read(loadingServiceProvider).hide();
          navigatorKey.currentState?.pop();
        }
      }
      
      break;
    }

    case "message_response": {
      await DatabaseService().messageDb.update(
        "messages",
        {
          "messageId": data["body"]["newMessageId"],
          "pending": 0,
        },
        where: "uId = ?",
        whereArgs: [data["body"]["uId"]]
      );

      ref.read(messageProvider).loadAll();
      break;
    }

    case "broadcast_message": {
      final String now = DateTime.now().toUtc().toIso8601String();

      data["body"]["uId"] = await PreferencesUtils().getInt("lastUId") ?? 0;
      data["body"]["pending"] = 0;
      data["body"]["receivedTimestamp"] = now;

      (data["body"] as Map).remove("receiversList");
      (data["body"] as Map).remove("_id");

      final MessageModel message = MessageModel.fromJson(data["body"]);
      ref.read(messageProvider).addMessage(message);
      
      final Map<String, dynamic> replyPayload = {
        "header": "received_message",
        "body": {
          "senderId":          message.senderId,
          "senderName":        message.senderName,
          "receiverId":        await secureStorage.getToken("userId"),
          "receiverName":      await secureStorage.getToken("username"),
          "messageId":         message.messageId,
          "chatId":            message.chatId,
          "text":              message.text,
          "receivedTimestamp": now,
        }
      };

      WebSocketService().sendMessage(jsonEncode(replyPayload));

      break;
    }
  }
}