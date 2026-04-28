import 'dart:async';

import 'package:hazelnut_shared/websocket_bus.dart';

class WebSocketBusImpl implements WebSocketBus {
  final Map<String, StreamController<dynamic>> _controllers = {};

  WebSocketBusImpl();
  static Future<WebSocketBusImpl> create() async {
    return WebSocketBusImpl();
  }

  @override
  void emit(String event, dynamic data) {
    if (_controllers.containsKey(event)) {
      try {
        _controllers[event]!.add(data);
      } catch (_) {}
    }
  }

  @override
  Stream<dynamic> on(String event) {
    final controller = _controllers.putIfAbsent(
      event,
      () => StreamController<dynamic>.broadcast(),
    );
    return controller.stream;
  }

  @override
  void off(String event) {
    final c = _controllers.remove(event);
    if (c != null) {
      try {
        c.close();
      } catch (_) {}
    }
  }
}