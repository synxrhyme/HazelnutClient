import 'package:hazelnut/deps.dart';
import 'package:hazelnut_shared/websocket_service.dart';

WebSocketService? _webSocketService;
AppDependencies? _dependencies;

void initializeWebSocketBridge(AppDependencies deps) {
  _dependencies = deps;
  _webSocketService = deps.webSocketService;
}

WebSocketService webSocketService() {
  if (_webSocketService == null) {
    throw StateError('WebSocket bridge not initialized. Call initializeWebSocketBridge() first.');
  }
  return _webSocketService!;
}

AppDependencies getAppDependencies() {
  if (_dependencies == null) {
    throw StateError('AppDependencies not initialized. Call initializeWebSocketBridge() first.');
  }
  return _dependencies!;
}

// Global getter for accessing dependencies anywhere in the app
AppDependencies get appDependencies => getAppDependencies();
