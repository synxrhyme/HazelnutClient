import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';
import 'preferences_service.dart';
import 'database_service.dart';
import 'websocket_service.dart' as ws_interface;
import 'websocket_bus.dart' as ws_bus_interface;

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

final appDependenciesProvider = Provider<AppDependencies>((ref) {
  throw UnimplementedError('appDependenciesProvider muss in app/ per override gesetzt werden');
});