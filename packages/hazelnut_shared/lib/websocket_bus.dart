abstract class WebSocketBus {
  void emit(String event, dynamic data);
  Stream<dynamic> on(String event);
  void off(String event);
}
