import 'package:flutter/widgets.dart';
import 'package:hazelnut_shared/auth_service.dart';
import 'package:hazelnut_shared/database_service.dart';
import 'package:hazelnut_shared/preferences_service.dart';
import 'package:hazelnut_shared/secure_storage_service.dart';
import 'package:hazelnut_shared/websocket_bus.dart';
import 'package:hazelnut_shared/websocket_service.dart';

class AuthServiceImpl extends AuthService {
  final WebSocketBus webSocketBus;
  final SecureStorageService secureStorageService;
  
  final PreferencesService prefsService;
  final DatabaseService databaseService;

  final WebSocketService webSocketService;

  AuthServiceImpl({
    required this.webSocketBus,
    required this.secureStorageService,
    required this.prefsService,
    required this.databaseService,
    required this.webSocketService,
  });

  @override
  Future<String> signUp(String username, String password) async {
    await Future.delayed(Duration(seconds: 2));
    return "dummy_token_for_$username";
  }

  @override
  Future<String?> signIn() async {
    await Future.delayed(Duration(seconds: 2));
    return "dummy_token_for_signed_in_user";
  }

  @override
  Future<void> signOut() async {
    secureStorage.deleteToken("username");
    secureStorage.deleteToken("userId");

    secureStorage.deleteToken("authToken");
    secureStorage.deleteToken("refreshToken");

    await prefsService.setBool("setupComplete", false);

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

    webSocketService().close(false);
    DatabaseService().clearAll();

    ChatProvider().loadChats();
    MessageProvider().loadAll();

  }
}