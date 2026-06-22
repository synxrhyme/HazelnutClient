import 'dart:async';

class WebSocketBus {
  final Map<String, StreamController<dynamic>> _controllers = {};

  WebSocketBus();
  static Future<WebSocketBus> create() async {
    return WebSocketBus();
  }

  void emit(String event, dynamic data) {
    if (_controllers.containsKey(event)) {
      try {
        _controllers[event]!.add(data);
      } catch (_) {}
    }
  }

  Stream<dynamic> on(String event) {
    final controller = _controllers.putIfAbsent(
      event,
      () => StreamController<dynamic>.broadcast(),
    );
    return controller.stream;
  }

  void off(String event) {
    final c = _controllers.remove(event);
    if (c != null) {
      try {
        c.close();
      } catch (_) {}
    }
  }
}