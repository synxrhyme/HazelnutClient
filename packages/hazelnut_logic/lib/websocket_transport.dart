import "dart:async";
import "dart:convert";
import "dart:io";

import "package:hazelnut_shared/websocket_transport.dart";

class WebSocketTransportImpl implements WebSocketTransport {
  WebSocket? _socket;
  String? _url;

  bool _forceClosed = false;
  bool _connected = false;
  bool _connecting = false;

  bool get isConnected => _connected;

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  DateTime? _lastPongTime;

  // Rohe eingehende Nachrichten (noch nicht entschlüsselt)
  final _inbound = StreamController<String>.broadcast();
  Stream<String> get messages => _inbound.stream;

  void Function()? onConnected;
  void Function()? onDisconnected;

  @override
  void setUrl(String url) => _url = url;

  @override
  Future<void> connect() async {
    if (_url == null || _connected || _connecting) return;

    _connecting = true;

    try {
      final socket = await WebSocket.connect(_url!).timeout(const Duration(seconds: 9));

      _socket = socket;
      _connected = true;
      _connecting = false;
      _forceClosed = false;

      _stopReconnectLoop();
      _startPing();

      onConnected?.call();

      _socket!.listen(
        (msg) => _inbound.add(msg.toString()),
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (_) {
      _connected = false;
      _connecting = false;
      _startReconnectLoop();
    }
  }

  @override
  void sendRaw(String data) {
    if (_socket == null || !_connected) return;
    try {
      _socket!.add(data);
    } catch (_) {}
  }

  void _startPing() {
    _pingTimer?.cancel();
    _lastPongTime = DateTime.now();

    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_connected || _socket == null) return;

      final diff = DateTime.now().difference(_lastPongTime ?? DateTime.now());
      if (diff.inSeconds > 30) {
        _socket?.close();
        _onDisconnected();
        return;
      }

      try {
        _socket!.add(jsonEncode({"type": "ping"}));
      } catch (_) {}
    });
  }

  void updatePong() {
    _lastPongTime = DateTime.now();
  }

  void _onDisconnected() {
    if (_forceClosed) return;

    _connected = false;
    _socket = null;
    _pingTimer?.cancel();

    onDisconnected?.call();
    _startReconnectLoop();
  }

  void _startReconnectLoop() {
    if (_reconnectTimer?.isActive ?? false || _forceClosed) return;

    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_connected && !_connecting && !_forceClosed) await connect();
    });
  }

  void _stopReconnectLoop() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  @override
  Future<void> disconnect(bool forceClose) async {
    _forceClosed = forceClose;
    if (forceClose) _stopReconnectLoop();
    _pingTimer?.cancel();

    await _socket?.close();
    _socket = null;
    _connected = false;
    _connecting = false;
  }
}
