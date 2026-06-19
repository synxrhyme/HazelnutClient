import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hazelnut_ui/components/notification_icon.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut_ui/pages/home_page.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/loading_provider.dart';
import 'package:hazelnut/utils/snackbar_utils.dart';
import 'package:hazelnut_logic/chat_provider.dart';
import 'package:hazelnut_logic/message_provider.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_shared/app_dependencies.dart';
import 'package:hazelnut_shared/database_service.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_shared/preferences_service.dart';
import 'package:hazelnut_shared/secure_storage_service.dart';
import 'package:hazelnut_shared/websocket_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (message.data["chatName"] == null || message.data["chatId"] == null) return;
  debugPrint("handling background");

  WidgetsFlutterBinding.ensureInitialized();
  final prefsService = await PreferencesServiceImpl.create();
  final int chatId = int.parse(message.data["chatId"]);
  
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await prefsService.reload();
  final String key = "chat_$chatId";

  final int? prevCount = await prefsService.getInt(key);
  if (prevCount == null) {
    debugPrint("First notification for chat $chatId, setting count to 1");
    return;
  }

  final int newCount = prevCount + 1;
  await prefsService.setInt(key, newCount);
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

Future<void> initFullServices() async {
  final dependencies = container.read(appDependenciesProvider);
  final WebSocketService webSocketService = dependencies.webSocketService;
  //final ChatNotifications chatNotifications = dependencies.cga;

  //await ChatNotifications().init();

  await dotenv.load(fileName: ".env");

  webSocketService.setUrl("wss://hazelnut.synxrhyme.com/ws/");
  await webSocketService.connect();
  webSocketService.onMessage = (data) => onMessage(data);
}

void onMessage(Map<String, dynamic> data) async {
  debugPrint(data.toString());
  final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

  final dependencies = container.read(appDependenciesProvider);
  final SecureStorageService secureStorage = dependencies.secureStorageService;
  final PreferencesService prefs = dependencies.prefsService;
  final DatabaseService databaseService = dependencies.databaseService;
  final WebSocketService webSocketService = dependencies.webSocketService;
  
  final ChatProvider chatProvider = container.read(chatProviderProvider);
  final MessageProvider messageProvider = container.read(messageProviderProvider);
  final LoadingService loader = container.read(loadingServiceProvider);
  
  switch (data["header"]) {
    case "registration_response": {
      switch (data["status"]) {
        case "success": {
          await secureStorage.saveToken("userId",       data["body"]["userId"].toString());
          await secureStorage.saveToken("username",     data["body"]["username"].toString());
          await secureStorage.saveToken("fcmToken",     data["body"]["fcmToken"].toString());

          await secureStorage.saveToken("authToken",    data["body"]["authToken"].toString());
          await secureStorage.saveToken("refreshToken", data["body"]["refreshToken"].toString());

          await prefs.setBool("setupComplete", true);
          webSocketService.close(false);

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

      loader.hide();
      break;
    }

    case "sync_messages_response": {
      switch (data["statusCode"]) {
        case 1: {
          if (await prefs.getBool("setupComplete") ?? false) return;

          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Falscher User",
            heightOffset: 50,
          );

          //authService.signout();
          break;
        }

        case 2: {
          if (await prefs.getBool("setupComplete") ?? false) return;

          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "User nicht bekannt",
            heightOffset: 50,
          );

          //authService.signout();
          return;
        }

        case 3: {
          webSocketService.refreshForAction(data["action"]);
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
          webSocketService.refreshForAction(data["action"]);
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

          //authService.signout();
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

          //authService.signout();
          return;
        }
      }

      loader.hide();
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
          chatProvider.addChat(chatModel);

          final List<Map<String,dynamic>> users = List<Map<String,dynamic>>.from(data["body"]["users"]);

          if (users.isNotEmpty) {
            for (final Map<String,dynamic> user_ in users) {
              final UserModel user = UserModel.fromJson(user_);
              if (user.userId != messageProvider.userId) chatModel.addUser(user);
            }

            chatProvider.loadChats();
          }
          
          showAnimatedSnackbarGlobal(
            icon: Icons.check_circle_outline,
            color1: theme.success.shade500!,
            color2: theme.success.shade500!,
            title: "Erfolgreich beigetreten",
            heightOffset: 50,
          );

          loader.hide();
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

          //authService.signout();
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

          //authService.signout();
          break;
        }

        case 6: {
          webSocketService.refreshForAction(data["action"]);
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

          //authService.signout();
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

          //authService.signout();
          break;
        }

        case 3: {
          webSocketService.refreshForAction(data["action"]);
          break;
        }

        case 0: {
          await databaseService.messageDb.update(
            "messages",
            {
              "messageId": data["body"]["newMessageId"],
              "pending": 0,
            },
            where: "uId = ?",
            whereArgs: [data["body"]["uId"]]
          );

          messageProvider.loadAll();
          break;
        }
      }

      break;
    }

    case "received_message_response": {
      if (data["statusCode"] == 1) {
        webSocketService.refreshForAction(data["action"]);
      }

      else if (data["statusCode"] == 2) {
        showAnimatedSnackbarGlobal(
          icon: Icons.error_outline_rounded,
          color1: theme.warning.shade500!,
          color2: theme.warning.shade400!,
          title: "Falscher User",
          heightOffset: 50,
        );

        //authService.signout();
        break;
      }

      break;
    }

    case "broadcast_message": {
      data["body"]["uId"] = await prefs.getInt("lastUId") ?? 0;
      data["body"]["pending"] = 0;

      (data["body"] as Map).remove("receiversList");
      (data["body"] as Map).remove("_id");

      final MessageModel message = MessageModel.fromJson(data["body"]);
      messageProvider.addMessage(message, true);
      
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

      webSocketService.sendMessage(jsonEncode(replyPayload));
      break;
    }
  }
}