import "package:hazelnut_shared/database_service.dart";
import "package:hazelnut_shared/preferences_service.dart";
import "package:hazelnut_shared/secure_storage_service.dart";
import "package:hazelnut_shared/websocket_bus.dart";
import "package:hazelnut_shared/websocket_transport.dart";

class WebSocketSessionImpl implements WebSocketSession {
  final WebSocketTransport _transport;
  final SecureStorageService _secureStorage;
  final PreferencesService _preferences;
  final WebSocketBus _bus;
  final DatabaseService _databaseService;
 
  WebSocketSessionImpl({
    required WebSocketTransport transport,
    required SecureStorageService secureStorage,
    required PreferencesService preferences,
    required WebSocketBus bus,
    required DatabaseService databaseService,
  })  : _transport = transport,
        _secureStorage = secureStorage,
        _preferences = preferences,
        _bus = bus,
        _databaseService = databaseService {
    // Transport-Callbacks verdrahten
    _transport.onConnected = _onTransportConnected;
    _transport.onDisconnected = _onTransportDisconnected;
 
    // Rohe Nachrichten vom Transport abhören
    _transport.messages.listen(_onRawMessage);
  }
