import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/loading_provider.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/util.dart';
import 'package:hazelnut_logic/websocket_bus.dart';
import 'package:hazelnut_logic/websocket_service.dart';

class AuthService {
  final WebSocketBus webSocketBus;
  final SecureStorageService secureStorageService;
  
  final PreferencesService prefsService;
  final DatabaseService databaseService;
  final WebSocketService webSocketService;

  final LoadingService loadingService;

  AuthService({
    required this.webSocketBus,
    required this.secureStorageService,
    required this.prefsService,
    required this.databaseService,
    required this.webSocketService,
    required this.loadingService,
  }) {
    _refreshForActionSub = webSocketBus.on('REFRESH_TOKEN_FOR_ACTION').listen((payload) async {
      final action = (payload as Map<String, dynamic>)['action'];
      await _refreshAndRetry(action);
    });

    _refreshSub = webSocketBus.on('REFRESH_TOKEN').listen((payload) async {
      await _refreshAndRetry(null);
    });

    _loginSub = webSocketBus.on("AUTHENTICATE").listen((payload) async {
      await signIn();
    });
  
    _loggedInSub = webSocketBus.on("AUTHENTICATED").listen((payload) async {
      _authenticated = true;
    });

    _deLoginSub = webSocketBus.on("DIS-AUTHENTICATE").listen((payload) async {
      _authenticated = false;
    });
    
    _signoutSub = webSocketBus.on("IVCRED_SIGNOUT").listen((payload) async {
      await signOut();
    });
  }

  StreamSubscription? _refreshForActionSub;
  StreamSubscription? _refreshSub;
  StreamSubscription? _loginSub;
  StreamSubscription? _loggedInSub;
  StreamSubscription? _deLoginSub;
  StreamSubscription? _signoutSub;

  bool _authenticated = false;
  set authenticated(bool value) => _authenticated = value;

  void signUp(BuildContext context, String username) {
    _sendRegistration(context, username);
  }

  Future<void> signIn() async {
    if (_authenticated) return;

    final String userId = await secureStorageService.getToken("userId");
    final String authToken = await secureStorageService.getToken("authToken");

    webSocketService.sendRaw(jsonEncode(
      {
        "header": "auth",
        "body": {
          "type": "login",
          "userId": userId,
          "authToken": authToken
        }
      }
    ));

    _authenticated = true;
  }

  Future<void> _sendRegistration(BuildContext context, String username) async {
    String fcmToken = await secureStorageService.getToken("fcmToken");
    final safeUsername = sanitizeRawInput(username, maxLength: 30);
    
    loadingService.show();

    Map<String, dynamic> request = {
      "header": "auth_request",
      "body": {
        "type": "signup",
        "username": safeUsername.toString(),
        "fcmToken": fcmToken.toString(),
      }
    };

    webSocketService.sendRaw(jsonEncode(request));

    loadingService.hide();
  }

  Future<void> _refreshAndRetry(Map<String, dynamic>? action) async {    
    webSocketService.authReady = false;
    if (action != null) webSocketService.sendMessage(jsonEncode(action)); // putting it in queue

    final String userId       = await secureStorageService.getToken("userId");
    final String refreshToken = await secureStorageService.getToken("refreshToken");

    if (refreshToken.isEmpty) {
      webSocketBus.emit("SHOW_SNACKBAR", {
        "severity": "error",
        "title": "Refresh-Token nicht gefunden",
      });

      signOut();
      return;
    }

    webSocketService.sendRaw(jsonEncode({
      "header": "refresh_request",
      "body": { "userId": userId, "token": refreshToken },
    }));
  }

  void appendCredentials() {} // append credentials to message, used in websocket service

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

  void dispose() {
    _refreshForActionSub?.cancel();
    _refreshSub?.cancel();
    _loggedInSub?.cancel();
    _loginSub?.cancel();
    _deLoginSub?.cancel();
    _signoutSub?.cancel();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final deps = ref.watch(appDependenciesProvider);

  return AuthService(
    webSocketBus:         deps.webSocketBus,
    secureStorageService: deps.secureStorageService,
    prefsService:         deps.prefsService,
    databaseService:      deps.databaseService,
    webSocketService:     deps.webSocketService,
    loadingService:       deps.loadingService,
  );
});