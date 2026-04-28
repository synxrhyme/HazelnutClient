abstract class WebSocketTransport {
  void setUrl(String url);
  //Future<void> Function(String message)? onMessage;

  Future<void> connect();
  void sendRaw(String data);
  Future<void> disconnect(bool forceClose);
}