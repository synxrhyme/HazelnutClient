import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hazelnut_logic/crypto_service.dart';
import 'package:hazelnut_logic/database_service.dart';
import 'package:hazelnut_logic/preferences_service.dart';
import 'package:hazelnut_logic/secure_storage_service.dart';
import 'package:hazelnut_logic/websocket_bus.dart';
import 'package:hazelnut_logic/websocket_handshake.dart';

class WebSocketService {
  final SecureStorageService secureStorage;
  final PreferencesService preferences;
  final WebSocketBus webSocketBus;
  final DatabaseService databaseService;
  final WebSocketHandshake handshake;
  final CryptoService cryptoService;

  WebSocketService({
    required this.webSocketBus,
    required this.secureStorage,
    required this.preferences,
    required this.databaseService,
    required this.handshake,
    required this.cryptoService,
  });

  void Function(Map<String, dynamic>)? onMessage;

  WebSocket? _socket;
  String? _url;

  Uint8List? get sessionKey => handshake.getSessionKey();

  bool _forceClosed = false;
  bool _connected = false;
  bool _connecting = false;

  bool get isConnected => _connected;

  final Queue<String> _messageQueue = Queue<String>();
  bool _ready = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  DateTime? _lastPongTime;

  void setUrl(String url) => _url = url;

  void setReady(bool value) {
    _ready = value;
    if (_ready) _flushQueue();
  }

  void _flushQueue() async {
    while (_messageQueue.isNotEmpty && _ready && _connected) {
      final msg = _messageQueue.removeFirst();
      sendMessage(msg);
    }

    final pendingMessages = await databaseService.getPendingMessages();
    if (pendingMessages == null) return;

    for (var msg in pendingMessages) {
      final message = {
        "header": "new_message",
        "body": msg.exportJson(),
      };
      sendMessage(jsonEncode(message));
    }
  }

  Future<void> connect() async {
    if (_url == null || _connected || _connecting) return;

    _connecting = true;

    try {
      final socket = await WebSocket.connect(_url!).timeout(const Duration(seconds: 9));
      _socket = socket;
      _connected = true;
      _connecting = false;
      _forceClosed = false;

      handshake.setSendMessage((msg) {
        _socket?.add(msg);
      });

      _stopReconnectLoop();
      _startPing();

      await handshake.initiate();

      _socket!.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (error) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[WebSocket] Connect failed: $e');
      _connected = false;
      _connecting = false;
      _startReconnectLoop();
    }
  }

  Future<void> sendMessageRaw(String raw) async {
    if (!_connected || !_ready || _forceClosed) {
      if (!_messageQueue.contains(raw)) _messageQueue.addLast(raw);
      return;
    }

    await _sendDirect(raw);
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

  void _onMessage(dynamic message) async {
    try {
      final raw = message.toString();
      Map<String, dynamic> rawData = jsonDecode(raw);

      if (rawData["type"] == "pong") {
        _lastPongTime = DateTime.now();
        return;
      }

      if (rawData["type"] == "key_exchange_response") {
        await handshake.handleResponse(rawData);
        await handshake.confirmKey({});
        return;
      }

      if (rawData["type"] == "enc") {
        final sessionKey = handshake.getSessionKey();
        if (sessionKey == null) return;

        final decrypted = await cryptoService.decryptAES(sessionKey, rawData);
        final data = jsonDecode(decrypted);

        _handleDecrypted(data);
      }
    } catch (e) {
      debugPrint('[WebSocket] Error processing message: $e');
    }
  }

  void _handleDecrypted(Map<String, dynamic> data) {
    switch (data["header"]) {
      case "handshake_response": {
        if (data["body"]["status"] == "success") {
          debugPrint("[WebSocket] Handshake erfolgreich, Verbindung gesichert");
          setReady(true);
        }
        break;
      }

      case "auth_response": {
        debugPrint("[WebSocket] Auth response: ${data["status"]}");
        if (data["status"] == "valid") {
          setReady(true);
        }
        break;
      }

      default:
        onMessage?.call(data);
    }
  }

  void _onDisconnected() {
    if (_forceClosed) return;

    _connected = false;
    _socket = null;
    _pingTimer?.cancel();
    handshake.reset();

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

  Future<void> sendMessage(String raw) async {
    if (!_connected || !_ready || _forceClosed) {
      if (!_messageQueue.contains(raw)) _messageQueue.addLast(raw);
      return;
    }

    final msg = jsonDecode(raw);
    msg["authToken"] = await secureStorage.getToken("authToken");
    msg["userId"] = await secureStorage.getToken("userId");

    await _sendDirect(jsonEncode(msg));
  }

  Future<void> _sendDirect(String raw) async {
    final sessionKey = handshake.getSessionKey();
    if (_socket == null || !_connected || sessionKey == null) return;

    final encrypted = await cryptoService.encryptAES(sessionKey, raw);
    _socket!.add(jsonEncode(encrypted));
  }

  Future<void> close(bool forceClose) async {
    _forceClosed = forceClose;
    if (forceClose) _stopReconnectLoop();
    _pingTimer?.cancel();

    await _socket?.close();
    _socket = null;
    _connected = false;
    _connecting = false;
    handshake.reset();
  }

  void refreshForAction(Map<String, dynamic> action) {
    // Logik für refresh, evtl. secureStorage verwenden
  }
}