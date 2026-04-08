import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/components/notification_icon.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/pages/home_page.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/chat_provider.dart';
import 'package:hazelnut/utils/database_service.dart';
import 'package:hazelnut/utils/loading_provider.dart';
import 'package:hazelnut/utils/local_notifications.dart';
import 'package:hazelnut/utils/message_provider.dart';
import 'package:hazelnut/utils/models.dart';
import 'package:hazelnut/utils/preferences_utils.dart';
import 'package:hazelnut/utils/secure_storage_service.dart';
import 'package:hazelnut/utils/signout.dart';
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
  rebuildNotificationNumberTrigger.value++;

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

    if (!firebaseBackgroundInitialized) FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    firebaseBackgroundInitialized = true;
  }));
}

Future<void> initFullServices(SecureStorageService secureStorage) async {
  await ChatNotifications().init();

  await dotenv.load(fileName: ".env");

  WebSocketService().setUrl("wss://hazelnut.synxrhyme.com/ws/");
  await WebSocketService().connect();
  WebSocketService().onMessage = onMessage;
}

void onMessage(Map<String, dynamic> data, WidgetRef ref) async {
  debugPrint(data.toString());
  final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;
  
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
          WebSocketService().close(false);

          navigatorKey.currentState?.push(
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 500),
              settings: RouteSettings(name: "homePage"),
              pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final slide = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

                return SlideTransition(
                  position: slide,
                  child: child,
                );
              },
            ),
          );

          break;
        }

        case "username_taken": {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Username schon vergeben!",
            heightOffset: 50,
          );

          break;
        }

        case "app_already_registered": {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Diese App wurde\nschon registriert??",
            heightOffset: 50,
          );

          break;
        }
      }

      ref.read(loadingServiceProvider).hide();
      break;
    }

    case "sync_messages_response": {
      switch (data["statusCode"]) {
        case 1: {
          if (await PreferencesUtils().getBool("setupComplete") ?? false) return;

          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Falscher User",
            heightOffset: 50,
          );

          signout();
          break;
        }

        case 2: {
          if (await PreferencesUtils().getBool("setupComplete") ?? false) return;

          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "User nicht bekannt",
            heightOffset: 50,
          );

          signout();
          return;
        }

        case 3: {
          WebSocketService().refreshForAction(data["action"]);
          return;
        }

        case 0: {
          if (data["messages"] == null || data["messages"]?.isEmpty ) return;

          /*
          
          final List<dynamic> messagesJson = data["messages"];
          final List<MessageModel> messages = messagesJson.map((msgJson) => MessageModel.fromJson(msgJson)).toList();
          
          
          for (final message in messages) {
            final bool exists = await DatabaseService().messageExists(message.messageId);

            if (!exists) {
              ref.read(messageProvider).addMessage(message, false);
              debugPrint("adding message ${message.toString()}");
            }
          }

          ref.read(messageProvider).loadAll();

          */
          
          break;
        }
      }

      break;
    }

    case "chat_creation_response": {
      switch (data["statusCode"]) {
        case 0: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Chatname schon vergeben",
            heightOffset: 50,
          );

          break;
        }

        case 1: {
          showAnimatedSnackbarGlobal(
            icon: Icons.check_circle_outline_rounded,
            color1 :theme.success.shade500!,
            color2 :theme.success.shade500!,
            title: "Chaterstellung erfolgreich",
            heightOffset: 50,
          );

          break;
        }

        case 2: {
          WebSocketService().refreshForAction(data["action"]);
          return;
        }

        case 3: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Falscher User",
            heightOffset: 50,
          );

          signout();
          break;
        }

        case 4: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Nutzer nicht bekannt",
            heightOffset: 50,
          );

          signout();
          return;
        }
      }

      ref.read(loadingServiceProvider).hide();
      break;
    }

    case "join_response": {
      debugPrint(data.toString());
      
      switch (data["statusCode"]) {
        case 0: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Kein Chatroom gefunden",
            heightOffset: 50,
          );

          break;
        }

        case 1: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Falsches Passwort",
            heightOffset: 50,
          );

          break;
        }

        case 2: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.info.shade500!,
            color2: theme.info.shade400!,
            title: "Du bist bereits Mitglied",
            heightOffset: 50,
          );

          break;
        }

        case 3: {
          final ChatModel chatModel = ChatModel.fromJson(data["body"]);
          ChatProvider().addChat(chatModel);

          final List<Map<String,dynamic>> users = List<Map<String,dynamic>>.from(data["body"]["users"]);

          if (users.isNotEmpty) {
            for (final Map<String,dynamic> user_ in users) {
              final UserModel user = UserModel.fromJson(user_);
              if (user.userId != MessageProvider().userId) chatModel.addUser(user);
            }

            ChatProvider().loadChats();
          }
          
          showAnimatedSnackbarGlobal(
            icon: Icons.check_circle_outline,
            color1: theme.success.shade500!,
            color2: theme.success.shade500!,
            title: "Erfolgreich beigetreten",
            heightOffset: 50,
          );

          ref.read(loadingServiceProvider).hide();
          navigatorKey.currentState?.pop();
          break;
        }

        case 4: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Falscher User",
            heightOffset: 50,
          );

          signout();
          break;
        }

        case 5: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "User nicht bekannt",
            heightOffset: 50,
          );

          signout();
          break;
        }

        case 6: {
          WebSocketService().refreshForAction(data["action"]);
          break;
        }
      }
      
      break;
    }

    case "message_response": {
      switch (data["statusCode"]) {
        case 1: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Falscher User",
            heightOffset: 50,
          );

          signout();
          break;
        }

        case 2: {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "User nicht bekannt",
            heightOffset: 50,
          );

          signout();
          break;
        }

        case 3: {
          WebSocketService().refreshForAction(data["action"]);
          break;
        }

        case 0: {
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
      }

      break;
    }

    case "received_message_response": {
      if (data["statusCode"] == 1) {
        WebSocketService().refreshForAction(data["action"]);
      }

      else if (data["statusCode"] == 2) {
        showAnimatedSnackbarGlobal(
          icon: Icons.error_outline_rounded,
          color1: theme.warning.shade500!,
          color2: theme.warning.shade400!,
          title: "Falscher User",
          heightOffset: 50,
        );

        signout();
        break;
      }

      break;
    }

    case "broadcast_message": {
      data["body"]["uId"] = await PreferencesUtils().getInt("lastUId") ?? 0;
      data["body"]["pending"] = 0;

      (data["body"] as Map).remove("receiversList");
      (data["body"] as Map).remove("_id");

      final MessageModel message = MessageModel.fromJson(data["body"]);
      ref.read(messageProvider).addMessage(message, true);
      
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
        }
      };

      WebSocketService().sendMessage(jsonEncode(replyPayload));
      break;
    }
  }
}