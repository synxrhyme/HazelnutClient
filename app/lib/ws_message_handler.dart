import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_logic/auth_service.dart';
import 'package:hazelnut_logic/chat_provider.dart';
import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/loading_provider.dart';
import 'package:hazelnut_logic/message_provider.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_service.dart';
import 'package:hazelnut_shared/models.dart';
import 'package:hazelnut_shared/status_codes.dart';
import 'package:hazelnut_ui/pages/main_page.dart';
import 'package:hazelnut_ui/snackbar_utils.dart';
import 'package:hazelnut_ui/theme.dart';

void onMessage(Map<String, dynamic> data) async {
  debugPrint(data.toString());

  final AppDependencies dependencies = container.read(appDependenciesProvider);
  final WebSocketService webSocketService = dependencies.webSocketService;
  final CustomColors theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

  //-- check message json format

  // Check for auth status
  switch (data["authStatusCode"]) {
    case StatusCodes.AUTH_TOKEN_EXPIRED: {
      webSocketService.refreshForAction(data["action"]);
      return;
    }

    case StatusCodes.AUTH_INVALID_TOKEN_FOR_USERID: {
      debugPrint("Invalid token for userId, signing out");
      container.read(authServiceProvider).signOut();

      showAnimatedSnackbarGlobal(
        navigatorKey: navigatorKey,
        icon: Icons.error_outline_rounded,
        color1: theme.warning.shade500!,
        color2: theme.warning.shade400!,
        title: "Falscher User",
        heightOffset: 50,
      );

      return;
    }

    case StatusCodes.AUTH_USER_NOT_FOUND: {
      debugPrint("User not found, signing out");
      container.read(authServiceProvider).signOut();

      showAnimatedSnackbarGlobal(
        navigatorKey: navigatorKey,
        icon: Icons.error_outline_rounded,
        color1: theme.warning.shade500!,
        color2: theme.warning.shade400!,
        title: "User unbekannt",
        heightOffset: 50,
      );

      return;
    }

    default: {
      debugPrint("Unknown authStatusCode: ${data["authStatusCode"]}");
      break;
    }
  }

  // No authStatusCode => success, proceed with handling the message

  final SecureStorageService secureStorage = dependencies.secureStorageService;
  final PreferencesService prefs = dependencies.prefsService;
  final DatabaseService databaseService = dependencies.databaseService;
  
  final ChatProvider chatProvider = container.read(chatProviderProvider);
  final MessageProvider messageProvider = container.read(messageProviderProvider);
  final LoadingService loader = container.read(loadingServiceProvider);
  
  switch (data["header"]) {
    case "registration_response": handleRegistrationResponse(data, dependencies);

    case "sync_messages_response": {
      // still todo
    }

    case "chat_creation_response": {
      switch (data["statusCode"]) {
        case StatusCodes.CHAT_ALREADY_EXISTS: {
          showAnimatedSnackbarGlobal(
            navigatorKey: navigatorKey,
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Chatname schon vergeben",
            heightOffset: 50,
          );

          break;
        }

        case StatusCodes.CHAT_CREATION_SUCCESSFUL: {
          showAnimatedSnackbarGlobal(
            navigatorKey: navigatorKey,
            icon: Icons.check_circle_outline_rounded,
            color1: theme.success.shade500!,
            color2: theme.success.shade500!,
            title: "Chaterstellung erfolgreich",
            heightOffset: 50,
          );

          break;
        }
      }

      loader.hide();
      break;
    }

    case "join_response": {      
      switch (data["statusCode"]) {
        case StatusCodes.CHAT_NOT_FOUND: {
          showAnimatedSnackbarGlobal(
            navigatorKey: navigatorKey,
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Kein Chatroom gefunden",
            heightOffset: 50,
          );

          break;
        }

        case StatusCodes.CHAT_WRONG_PASSWORD: {
          showAnimatedSnackbarGlobal(
            navigatorKey: navigatorKey,
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Falsches Passwort",
            heightOffset: 50,
          );

          break;
        }

        case StatusCodes.CHAT_ALREADY_JOINED: {
          showAnimatedSnackbarGlobal(
            navigatorKey: navigatorKey,
            icon: Icons.error_outline_rounded,
            color1: theme.info.shade500!,
            color2: theme.info.shade400!,
            title: "Du bist bereits Mitglied",
            heightOffset: 50,
          );

          break;
        }

        case StatusCodes.CHAT_JOIN_SUCCESSFUL: {
          final ChatModel chatModel = ChatModel.fromJson(data["body"]);
          chatProvider.addChat(chatModel);

          final List<Map<String,dynamic>> users = List<Map<String,dynamic>>.from(data["body"]["users"]);

          if (users.isNotEmpty) {
            for (final Map<String,dynamic> user_ in users) {
              final UserModel user = UserModel.fromJson(user_);
              if (user.userId != container.read(authServiceProvider).userId) {
                databaseService.addUserToChat(chatModel.chatId, user);
                chatProvider.loadChats();
              }
            }

            chatProvider.loadChats();
          }
          
          showAnimatedSnackbarGlobal(
            navigatorKey: navigatorKey,
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
      }
      
      break;
    }

    case "message_response": {
      switch (data["statusCode"]) {
        case StatusCodes.MESSAGE_SENT_SUCCESSFULLY: {
          debugPrint("Message sent successfully, updating pending status");
          databaseService.markMessageSent(data["body"]["messageId"]);
          messageProvider.loadAll();
          break;
        }

        case StatusCodes.MESSAGE_ID_TAKEN: {
          //await databaseService.markMessageSent(data["body"]["uId"], data["body"]["newMessageId"]);
          //debugPrint("Message sent successfully, updating local database and refreshing message list");
          //messageProvider.loadAll();
          //break;
        }
      }

      break;
    }

    case "received_message_response": {
      // no action, only used when token is expired in message_received packet
    }

    case "broadcast_message": {
      data["body"]["pending"] = 0;

      (data["body"] as Map).remove("receiversList");
      (data["body"] as Map).remove("_id");

      final MessageModel message = MessageModel.fromJson(data["body"]);
      await databaseService.insertMessageIntoDb(message);
      messageProvider.loadAll();
      
      final Map<String, dynamic> replyPayload = {
        "header": "received_message",
        "messageId": message.messageId,
      };

      webSocketService.sendMessage(jsonEncode(replyPayload));
      break;
    }
  }
}

void handleRegistrationResponse(Map<String, dynamic> data, AppDependencies dependencies) async {
  final SecureStorageService secureStorage = dependencies.secureStorageService;
  final PreferencesService prefs = dependencies.prefsService;
  final WebSocketService webSocketService = dependencies.webSocketService;

  final CustomColors theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

  switch (data["status"]) {
    case "success": {
      await secureStorage.saveToken("userId",       data["body"]["userId"].toString());
      await secureStorage.saveToken("username",     data["body"]["username"].toString());
      await secureStorage.saveToken("fcmToken",     data["body"]["fcmToken"].toString());

      await secureStorage.saveToken("authToken",    data["body"]["authToken"].toString());
      await secureStorage.saveToken("refreshToken", data["body"]["refreshToken"].toString());

      await prefs.setBool("setupComplete", true);
      webSocketService.close(false);

      navigatorKey.currentState?.pushAndRemoveUntil(
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
        (route) => false,
      );

      LoadingService loadingService = container.read(loadingServiceProvider);
      loadingService.hide();

      break;
    }

    case "username_taken": {
      showAnimatedSnackbarGlobal(
        navigatorKey: navigatorKey,
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
        navigatorKey: navigatorKey,
        icon: Icons.error_outline_rounded,
        color1: theme.warning.shade500!,
        color2: theme.warning.shade400!,
        title: "Diese App wurde\nschon registriert??", // How did this happen?
        heightOffset: 50,
      );

      break;
    }
  }
}