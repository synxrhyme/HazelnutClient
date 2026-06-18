import 'dart:typed_data';

abstract class WebSocketHandshake {
  void setSendMessage(Function(String) sendMessage);

  Future<void> initiate();
  Future<void> handleResponse(Map<String, dynamic> data);
  Future<void> confirmKey(Map<String, dynamic> data);

  Uint8List? getSessionKey();
  void reset();
}
