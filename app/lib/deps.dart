import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_service.dart';
import 'package:hazelnut_logic/websocket_bus.dart';
import 'package:hazelnut_logic/websocket_handshake.dart';
import 'package:hazelnut_logic/crypto_service.dart';
import 'package:hazelnut_shared/database_service.dart';
import 'package:hazelnut_shared/preferences_service.dart';
import 'package:hazelnut_shared/secure_storage_service.dart';
import 'package:hazelnut_shared/websocket_service.dart' as ws_interface;
import 'package:hazelnut_shared/websocket_bus.dart' as ws_bus_interface;

class AppDependencies {
  final SecureStorageService secureStorageService;
  final PreferencesService prefsService;
  final DatabaseService databaseService;
  final ws_interface.WebSocketService webSocketService;
  final ws_bus_interface.WebSocketBus webSocketBus;

  AppDependencies({
    required this.secureStorageService,
    required this.prefsService,
    required this.databaseService,
    required this.webSocketService,
    required this.webSocketBus,
  });
}

Future<AppDependencies> createDependencies() async {
  final secureStorageService = SecureStorageServiceImpl();
  final prefsService = await PreferencesServiceImpl.create();
  final databaseService = await DatabaseServiceImpl.create(preferences: prefsService);

  final cryptoService = CryptoServiceImpl();
  final webSocketBus = WebSocketBusImpl();
  final handshake = WebSocketHandshakeImpl(
    cryptoService: cryptoService,
  );

  final webSocketService = WebSocketServiceImpl(
    webSocketBus: webSocketBus,
    secureStorage: secureStorageService,
    preferences: prefsService,
    databaseService: databaseService,
    handshake: handshake,
    cryptoService: cryptoService,
  );

  return AppDependencies(
    secureStorageService: secureStorageService,
    prefsService: prefsService,
    databaseService: databaseService,
    webSocketService: webSocketService,
    webSocketBus: webSocketBus,
  );
}