import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/deps.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/ws_message_handler.dart';
import 'package:hazelnut_logic/app_dependencies.dart';
import 'package:hazelnut_logic/app_state_provider.dart';
import 'package:hazelnut_logic/auth_service.dart';
import 'package:hazelnut_logic/chat_provider.dart';
import 'package:hazelnut_logic/message_provider.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_service.dart';
import 'package:hazelnut_shared/navigation.dart';
import 'package:hazelnut_ui/components/notification_icon.dart';
import 'package:hazelnut_ui/pages/setup_page.dart';
import 'package:hazelnut_ui/snackbar_utils.dart';
import 'package:hazelnut_ui/theme.dart';

class InitService {
  static Future<void> initialize() async {
    final dependencies = await createDependencies(navigatorKey);
    final setupComplete = await dependencies.prefsService.getBool("setupComplete") ?? false;

    container = ProviderContainer(
      overrides: [
        appDependenciesProvider.overrideWithValue(dependencies),
        setupCompleteProvider.overrideWithValue(setupComplete),
        navigatorKeyProvider.overrideWithValue(navigatorKey),
      ],
    );

    container.read(authServiceProvider);
    container.read(chatProviderProvider).loadChats();
    container.read(messageProviderProvider).loadAll();

    // alles weitere was vor App-Start fertig sein muss:
    await initFirebase(dependencies.secureStorageService);
    await initFullServices();

    dependencies.webSocketBus.on('USER_SIGNED_OUT').listen((_) {
      container.updateOverrides([
        appDependenciesProvider.overrideWithValue(dependencies),
        setupCompleteProvider.overrideWithValue(false),
        navigatorKeyProvider.overrideWithValue(navigatorKey),
      ]);

      navigatorKey.currentState?.pushAndRemoveUntil(
        PageRouteBuilder(
          settings: RouteSettings(name: "setupPage"),
          pageBuilder: (context, animation, _) => SetupPage(),
          transitionsBuilder: (context, animation, _, child) {
            final slide = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
            return SlideTransition(position: slide, child: child);
          },
        ),
        (route) => false,
      );
    });

    initWebSocketBusListeners(dependencies);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    FlutterNativeSplash.remove();
  }

  static void initWebSocketBusListeners(AppDependencies dependencies) {
    dependencies.webSocketBus.on('SHOW_SNACKBAR').listen((payload) {
      final p = payload as Map<String, dynamic>;
      final ctx = rootScaffoldMessengerKey.currentContext;
        
      if (ctx == null || !ctx.mounted) return;
      final theme = Theme.of(ctx).extension<CustomColors>()!;
    
      Color? color1;
      Color? color2;
      IconData? icon;
      
      switch (p["severity"]) {
        case "error": {
          color1 = theme.error.shade500!;
          color2 = theme.error.shade400!;
          icon = Icons.error_outline_rounded;
        }
    
        case "info": {
          color1 = theme.info.shade500!;
          color2 = theme.info.shade400!;
          icon = Icons.error_outline_rounded;
        }
    
        case "success": {
          color1 = theme.success.shade500!;
          color2 = theme.success.shade400!;
          icon = Icons.check_circle_outline_rounded;
        }
    
        default: {
          color1 = Colors.white;
          color2 = Colors.white;
          icon = Icons.question_mark_rounded;
        }
      }
    
      showAnimatedSnackbarGlobal(
        navigatorKey: navigatorKey,
        icon: icon,
        color1: color1,
        color2: color2,
        title: p["title"],
        heightOffset: 50,
      );
    });
  }
}

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (message.data["chatName"] == null || message.data["chatId"] == null) return;
  debugPrint("handling background");

  WidgetsFlutterBinding.ensureInitialized();
  final prefsService = await PreferencesService.create();
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
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase.initializeApp() ist meist lokal und offline-tolerant, aber sicherheitshalber trotzdem abfangen
    return;
  }

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    await messaging
        .subscribeToTopic("HazelnutMessenger")
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    // kein Internet o.ä. – Push-Subscription kann später nachgeholt werden
  }

  try {
    final String savedToken = await secureStorage.getToken("fcmToken");
    if (savedToken.isEmpty) {
      final String fcmToken = await messaging
          .getToken()
          .timeout(const Duration(seconds: 5))
          ?? "";
      if (fcmToken.isNotEmpty) {
        await secureStorage.saveToken("fcmToken", fcmToken);
      }
    }
  } catch (e) {
    // Token-Abruf fehlgeschlagen – App läuft trotzdem weiter
  }

  if (!firebaseBackgroundInitialized) {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    firebaseBackgroundInitialized = true;
  }
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