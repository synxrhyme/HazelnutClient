abstract class WebsocketSession {
  void setUrl(String url);
  Future<void> Function(String message)? onMessage;

  Future<void> connect(String url);
  Future<void> send(String message);

  Future<void> disconnect();
}