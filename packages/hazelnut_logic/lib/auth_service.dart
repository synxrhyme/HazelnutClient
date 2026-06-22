import 'package:flutter/widgets.dart';
import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_bus.dart';
import 'package:hazelnut_logic/websocket_service.dart';

class AuthService {
  final GlobalKey<NavigatorState> navigatorKey;
  final WebSocketBus webSocketBus;
  final SecureStorageService secureStorageService;
  
  final PreferencesService prefsService;
  final DatabaseService databaseService;

  final WebSocketService webSocketService;

  AuthService({
    required this.webSocketBus,
    required this.secureStorageService,
    required this.prefsService,
    required this.databaseService,
    required this.webSocketService,
    required this.navigatorKey
  });

  Future<String> signUp(String username, String password) async {
    await Future.delayed(Duration(seconds: 2));
    return "dummy_token_for_$username";
  }

  Future<String?> signIn() async {
    await Future.delayed(Duration(seconds: 2));
    return "dummy_token_for_signed_in_user";
  }

  Future<void> signOut() async {
    secureStorageService.deleteToken("username");
    secureStorageService.deleteToken("userId");
    secureStorageService.deleteToken("authToken");
    secureStorageService.deleteToken("refreshToken");

    await prefsService.setBool("setupComplete", false);

    databaseService.clearAll();
    webSocketService.close(false);
    webSocketBus.emit('USER_SIGNED_OUT', {});
  }
}