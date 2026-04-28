abstract class WebSocketService {
  void setUrl(String url);
  void setReady(bool value);

  Future<void> connect();
  void close(bool forceClose);

  void refreshForAction(Map<String, dynamic> action);

  void Function(Map<String, dynamic>, dynamic)? onMessage;
  bool get isConnected;

  Future<void> sendMessage(String raw);
  Future<void> sendMessageRaw(String raw);

}