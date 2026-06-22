import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_bus.dart';
import 'package:hazelnut_logic/websocket_service.dart';

class AppDependencies {
  final SecureStorageService secureStorageService;
  final PreferencesService prefsService;
  final DatabaseService databaseService;
  final WebSocketService webSocketService;
  final WebSocketBus webSocketBus;

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