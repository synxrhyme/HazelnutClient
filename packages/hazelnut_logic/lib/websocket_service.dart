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
  bool _connected   = false;
  bool _connecting  = false;

  bool get isConnected => _connected;

  // Zwei getrennte Queues: Raw-Nachrichten bekommen nie Auth-Header,
  // Auth-Nachrichten immer – sie dürfen nicht vermischt werden.
  final Queue<String> _rawQueue  = Queue<String>();
  final Queue<String> _authQueue = Queue<String>();

  bool _transportReady = false;
  bool _authReady = false;

  set transportReady(bool value) => _transportReady = value;

  set authReady(bool value) {
    _authReady = value;
    if (_authReady) _flushQueues();
  }

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  DateTime? _lastPongTime;

  void setUrl(String url) => _url = url;

  // ── Private: roher Socket-Schreiber ──────────────────────────────────────
  // Kein Encrypt, kein Auth. Wird ausschließlich vom Handshake genutzt.
  void _sendPlain(dynamic data) {
    _socket?.add(data);
  }

  // ── Private: verschlüsseln + direkt senden ───────────────────────────────
  // Kein Queue-Check, kein Auth. Interner Basisbaustein für sendRaw/sendMessage.
  Future<void> _sendEncrypted(String raw) async {
    final key = handshake.getSessionKey();
    if (_socket == null || !_connected || key == null) return;

    final encrypted = await cryptoService.encryptAES(key, raw);
    debugPrint("raw: $raw");
    _socket!.add(jsonEncode(encrypted));
  }

  // ── Public: verschlüsselt senden, kein Auth-Header ───────────────────────
  // Für Nachrichten, die keinen authToken/userId brauchen (z. B. Registration,
  // wo der User noch kein Token hat).
  Future<void> sendRaw(String raw) async {
    if (!_connected || !_transportReady || _forceClosed) {
      if (!_rawQueue.contains(raw)) _rawQueue.addLast(raw);
      return;
    }
    await _sendEncrypted(raw);
  }

  // ── Public: Auth-Header anhängen, verschlüsselt senden ───────────────────
  // Für alle normalen App-Nachrichten nach dem Login. Hängt authToken und
  // userId aus dem SecureStorage an bevor verschlüsselt wird.
  Future<void> sendMessage(String raw) async {
    if (!_connected || !_transportReady || !_authReady || _forceClosed) {
      if (!_authQueue.contains(raw)) _authQueue.addLast(raw);
      return;
    }
    await _sendWithAuth(raw);
  }

  Future<void> _sendWithAuth(String raw) async {
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    msg["authToken"] = await secureStorage.getToken("authToken");
    msg["userId"]    = await secureStorage.getToken("userId");
    await _sendEncrypted(jsonEncode(msg));
  }

  // ── Queue-Flush ───────────────────────────────────────────────────────────
  Future<void> _flushQueues() async {
    // Raw-Queue: direkt verschlüsselt senden, kein Auth
    while (_rawQueue.isNotEmpty && _transportReady && _connected) {
      await _sendEncrypted(_rawQueue.removeFirst());
    }

    // Auth-Queue: Auth-Header anhängen, dann verschlüsselt senden
    while (_authQueue.isNotEmpty && _authReady && _connected) {
      await _sendWithAuth(_authQueue.removeFirst());
    }

    // Pending messages aus der DB (immer mit Auth, da post-login)
    final pendingMessages = await databaseService.getPendingMessages();
    if (pendingMessages == null) return;

    for (final msg in pendingMessages) {
      await sendMessage(jsonEncode({
        "header": "new_message",
        "body":   msg.exportJson(),
      }));
    }
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> connect() async {
    if (_url == null || _connected || _connecting) return;
    _connecting = true;

    try {
      final socket = await WebSocket.connect(_url!).timeout(const Duration(seconds: 9));
      _socket     = socket;
      _connected  = true;
      _connecting = false;
      _forceClosed = false;

      // Handshake bekommt _sendPlain – kein Encrypt beim Schlüsselaustausch
      handshake.setSendMessage(_sendPlain);

      _stopReconnectLoop();
      _startPing();
      await handshake.initiate();

      _socket!.listen(
        _onMessage,
        onDone:       _onDisconnected,
        onError:      (_) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[WebSocket] Connect failed: $e');
      _connected  = false;
      _connecting = false;
      _startReconnectLoop();
    }
  }

  // ── Empfangen ─────────────────────────────────────────────────────────────
  void _onMessage(dynamic message) async {
    try {
      final raw = message.toString();
      final Map<String, dynamic> rawData = jsonDecode(raw);

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
        final key = handshake.getSessionKey();
        if (key == null) return;

        final decrypted = await cryptoService.decryptAES(key, rawData);
        await _handleDecrypted(jsonDecode(decrypted));
      }
    } catch (e) {
      debugPrint('[WebSocket] Error processing message (${message.toString()}): $e');
    }
  }

  Future<void> _handleDecrypted(Map<String, dynamic> data) async {
    switch (data["header"]) {
      case "handshake_response": {
        if (data["status"] == "success") {
          debugPrint("[WebSocket] Handshake erfolgreich, Verbindung gesichert");
          _transportReady = true;

          final bool setupComplete = await preferences.getBool("setupComplete") ?? false;

          if (setupComplete) {
            webSocketBus.emit("AUTHENTICATE", {});
            debugPrint("[WebSocket] authenticating");
          }

          else {
            debugPrint("[WebSocket] waiting for sign in");

            final Map<String, dynamic> authPayload = {
              "header": "auth",
              "body": { "type": "signup" }
            };

            sendRaw(jsonEncode(authPayload));
          }
        }

        else {
          close(false);
        }

        break;
      }

      case "auth_response": {
        debugPrint("[WebSocket] Auth response: ${data["status"]}");

        if (data["status"] == "valid") { _authReady = true; }
        
        else if (data["status"] == "token_invalid") {
          webSocketBus.emit('REFRESH_TOKEN', {});
        }

        break;
      }

      case "refresh_response": {
        debugPrint("[WebSocket] Refresh response: ${data["status"]}");

        if (data["status"] == "success") {
          secureStorage.saveToken("authToken", data["body"]["authToken"]);
          webSocketBus.emit("AUTHENTICATE", {});
        }
        
        else if (data["status"] == "user_invalid") {
          webSocketBus.emit("IVCRED_SIGNOUT", {});
        }

        else {
          debugPrint("refresh error");
        }
      }

      default:
        onMessage?.call(data);
    }
  }

  // ── Ping ──────────────────────────────────────────────────────────────────
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

  // ── Disconnect / Reconnect ────────────────────────────────────────────────
  void _onDisconnected() {
    if (_forceClosed) return;
    _connected = false;
    _socket    = null;
    _authReady = false;
    _transportReady = false;
    _pingTimer?.cancel();
    handshake.reset();

    webSocketBus.emit("DIS-AUTHENTICATE", {});
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

  Future<void> close(bool forceClose) async {
    _forceClosed = forceClose;
    if (forceClose) _stopReconnectLoop();
    _pingTimer?.cancel();
    _authReady = false;
    _transportReady = false;

    await _socket?.close();
    _socket    = null;
    _connected = false;
    _connecting = false;
    handshake.reset();

    webSocketBus.emit("DIS-AUTHENTICATE", {});
  }

  void refreshForAction(Map<String, dynamic> action) {
    webSocketBus.emit('REFRESH_TOKEN_FOR_ACTION', {'action': action});
  }
}