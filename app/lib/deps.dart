import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_service.dart';
import 'package:hazelnut_logic/websocket_bus.dart';
import 'package:hazelnut_logic/websocket_handshake.dart';
import 'package:hazelnut_logic/crypto_service.dart';
import 'package:hazelnut_shared/app_dependencies.dart';

Future<AppDependencies> createDependencies() async {
  final secureStorageService = SecureStorageService();
  final prefsService = await PreferencesService.create();
  final databaseService = await DatabaseService.create(preferences: prefsService);

  final cryptoService = CryptoService();
  final webSocketBus = WebSocketBus();
  final handshake = WebSocketHandshake(cryptoService: cryptoService);

  final webSocketService = WebSocketService(
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