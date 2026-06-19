import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_service.dart';
import 'package:hazelnut_logic/websocket_bus.dart';
import 'package:hazelnut_logic/websocket_handshake.dart';
import 'package:hazelnut_logic/crypto_service.dart';
import 'package:hazelnut_shared/app_dependencies.dart';

Future<AppDependencies> createDependencies() async {
  final secureStorageService = SecureStorageServiceImpl();
  final prefsService = await PreferencesServiceImpl.create();
  final databaseService = await DatabaseServiceImpl.create(preferences: prefsService);

  final cryptoService = CryptoServiceImpl();
  final webSocketBus = WebSocketBusImpl();
  final handshake = WebSocketHandshakeImpl(
    cryptoService: cryptoService,
  );

  //final MessageProvider messageProvider = MessageProvider();
  //final ChatProvider chatProvider = ChatProvider();
  //final UserProvider userProvider = UserProviderImpl.create();

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
   //messageProvider: messageProvider,
   //chatProvider: chatProvider,
  );
}