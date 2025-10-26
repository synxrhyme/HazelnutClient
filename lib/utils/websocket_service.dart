import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/utils/database_service.dart';
import "package:hazelnut/utils/encryption_utils.dart";
import 'package:hazelnut/utils/preferences_utils.dart';
import 'package:hazelnut/utils/signout.dart';
import 'package:hazelnut/utils/snackbar_utils.dart';

class WebSocketService {
  late WidgetRef _ref;

  WebSocketService._internal();
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocket? _socket;
  String? _url;

  Uint8List? _sessionKey;
  Uint8List? get sessionKey => _sessionKey;

  bool _forceClosed = false;
  bool _connected = false;
  bool _connecting = false;
  bool get isConnected => _connected;

  bool showingError = false;

  final Queue<String> _messageQueue = Queue<String>();
  bool _ready = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  DateTime? _lastPongTime;

  void Function(Map<String, dynamic>, WidgetRef)? onMessage;

  void init(WidgetRef ref) => _ref = ref;
  void setUrl(String url) => _url = url;

  void setReady(bool value) {
    _ready = value;
    if (_ready) {
      _flushQueue();
      _startPing();
    }
  }

  void _flushQueue() async {
    while (_messageQueue.isNotEmpty && _ready && _connected) {
      final msg = _messageQueue.removeFirst();
      sendMessage(msg);
    }

    final pendingMessages = await DatabaseService().getPendingMessages();
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
    if (_url == null) return;
    if (_connected || _connecting) return;

    _connecting = true;
    debugPrint('[WebSocket] Connecting to $_url...');

    try {
      final socket = await WebSocket.connect(_url!).timeout(const Duration(seconds: 9));

      _socket = socket;
      _connected = true;
      _connecting = false;
      _forceClosed = false;

      debugPrint('[WebSocket] Connected.');
      _stopReconnectLoop();

      final serverKey = await fetchServerKey("https://hazelnut.synxrhyme.com/public.pem");

      final rawSessionKey = generateRawAesKey();
      final encryptedKey = encryptAesKey(rawSessionKey, serverKey);

      _sessionKey = rawSessionKey;

      final data = jsonEncode({
        "type": "session_key",
        "key": encryptedKey,
      });

      _socket!.add(data);
      debugPrint("[WebSocket] Session-Key gesendet: $data");

      _socket!.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (error) {
          debugPrint('[WebSocket] Error: $error');
          _onDisconnected();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[WebSocket] Connect failed: $e');
      _connected = false;
      _connecting = false;
      _startReconnectLoop();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _lastPongTime = DateTime.now();

    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_connected || _socket == null) return;

      final now = DateTime.now();
      final diff = now.difference(_lastPongTime ?? now);

      if (diff.inSeconds > 30) {
        debugPrint('[WebSocket] ⚠️ Keine Pong-Antwort seit ${diff.inSeconds}s — reconnect...');
        _socket?.close();
        _onDisconnected();
        return;
      }

      try {
        _socket!.add(jsonEncode({"type": "ping"}));
        debugPrint('[WebSocket] Ping gesendet.');
      } catch (e) {
        debugPrint('[WebSocket] Ping send error: $e');
      }
    });
  }

  void _onMessage(dynamic message) async {
    try {
      final msg = message.toString();

      if (msg.contains('"type":"pong"')) {
        _lastPongTime = DateTime.now();
        return;
      }

      Map<String, dynamic> rawData = jsonDecode(msg);
      final key = _sessionKey;
      if (key == null) return;

      if (rawData["type"] == "enc") {
        final decrypted = await decryptAES(key, rawData);
        final data = jsonDecode(decrypted);

        _handleDecrypted(data);
      }
    } catch (error, stack) {
      debugPrint("error: $error");
      debugPrint(stack.toString());
    }
  }

  void _handleDecrypted(Map<String, dynamic> data) async {
    final String userId = await secureStorage.getToken("userId");

    switch (data["header"]) {
      case "session_key_response": {
        if (data["status"] == "success") {
          if (await PreferencesUtils().getBool("setupComplete") == false) {
            setReady(true);
            debugPrint("[WebSocket] Setup not complete, skipping auth. -- ready");
            return;
          }

          final authToken = await secureStorage.getToken("authToken");
          if (authToken.isEmpty) {
            signout();
            return;
          }

          _sendDirect(jsonEncode({
            "header": "auth",
            "body": {"userId": userId, "token": authToken},
          }));
        } else {
          _socket?.close();
        }

        break;
      }

      case "auth_response": {
        if (data["status"] == "valid") {
          setReady(true);
        } else if (data["status"] == "token_invalid") {
          final refreshToken = await secureStorage.getToken("refreshToken");
          if (refreshToken.isEmpty) {
            signout();
            return;
          }

          _sendDirect(jsonEncode({
            "header": "refresh",
            "body": {"userId": userId, "token": refreshToken},
          }));
        } else if (data["status"] == "user_invalid") {
          signout();
        }

        break;
      }

      case "refresh_response": {
        if (data["status"] == "valid") {
          final newAuthToken = data["body"]["authToken"];
          await secureStorage.saveToken("authToken", newAuthToken);
          _sendDirect(jsonEncode({
            "header": "auth",
            "body": {"userId": userId, "token": newAuthToken},
          }));
        } else if (data["status"] == "user_invalid") {
          signout();
        }

        break;
      }

      case "force_signout": signout();

      default:
        onMessage?.call(data, _ref);
    }
  }

  void _onDisconnected() {
    if (_forceClosed) return;

    _connected = false;
    _socket = null;
    _pingTimer?.cancel();

    debugPrint('[WebSocket] Connection lost.');
    _startReconnectLoop();
  }

  void _startReconnectLoop() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_forceClosed) return;
  
    debugPrint('[WebSocket] Starting reconnect loop...');
    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_connected || _connecting || _forceClosed) return;
  
      debugPrint('[WebSocket] Trying reconnect...');
      await connect();
    });
  }

  void _stopReconnectLoop() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> sendMessage(String message) async {
    if (_forceClosed) {
      showWebsocketErrorSnackbar();
      return;
    }

    if (!_connected || !_ready) {
      if (!_messageQueue.contains(message)) {
        _messageQueue.addLast(message);
      }

      return;
    }

    _sendDirect(message);
  }

  Future<void> _sendDirect(String message) async {
    if (_socket == null || !_connected) return;

    try {
      final encrypted = await encryptAES(_sessionKey!, message);
      final data = jsonEncode({
        "type": "enc",
        "iv": encrypted["iv"],
        "data": encrypted["data"],
        "tag": encrypted["tag"],
      });

      debugPrint('[WebSocket] Sending message: $message');
      _socket!.add(data);
    } catch (e) {
      showWebsocketErrorSnackbar();
    }
  }

  Future<void> close(bool forceClose) async {
    _forceClosed = forceClose;
    if (forceClose) _stopReconnectLoop();
    _pingTimer?.cancel();

    await _socket?.close();
    _socket = null;

    _connected = false;
    _connecting = false;

    debugPrint('[WebSocket] Connection closed by user, forced: $forceClose');
  }
}

/*
class WebSocketService {
  late WidgetRef _ref;

  WebSocketService._internal();
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  
  WebSocket? _socket;
  String? _url;

  Uint8List? _sessionKey;
  Uint8List? get sessionKey => _sessionKey;

  bool _forceClosed = false;
  bool _connected = false;
  bool _connecting = false;
  bool get isConnected => _connected;

  bool showingError = false;

  final Queue<String> _messageQueue = Queue<String>();
  bool _ready = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  DateTime? _lastPongTime;

  void Function(Map<String, dynamic>, WidgetRef)? onMessage;
  void init(WidgetRef ref) => _ref = ref;
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

    List<MessageModel>? pendingMessages = await DatabaseService().getPendingMessages();
    if (pendingMessages == null) return;

    for (var msg in pendingMessages) {
      final message = {
        "header": "new_message",
        "body": msg.exportJson()
      };

      sendMessage(jsonEncode(message));
    }
  }

  Future<void> connect() async {
    if (_url == null) return;
    if (_connected || _connecting) return;

    _connecting = true;
    debugPrint('[WebSocket] Connecting to $_url...');

    try {
      final socket = await WebSocket.connect(_url!).timeout(const Duration(seconds: 9));

      _socket = socket;
      _connected = true;
      _connecting = false;
      _forceClosed = false;

      debugPrint('[WebSocket] Connected.');
      _stopReconnectLoop();

      final serverKey = await fetchServerKey("https://hazelnut.synxrhyme.com/public.pem");

      final rawSessionKey = generateRawAesKey();
      final encryptedKey = encryptAesKey(rawSessionKey, serverKey);

      _sessionKey = rawSessionKey;

      final data = jsonEncode({
        "type": "session_key",
        "key": encryptedKey,
      });

      _socket!.add(data);
      debugPrint("[WebSocket] Session-Key gesendet: $data");

      _socket!.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (error) {
          debugPrint('[WebSocket] Error: $error');
          _onDisconnected();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[WebSocket] Connect failed: $e');
      _connected = false;
      _connecting = false;
      _startReconnectLoop();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _lastPongTime = DateTime.now();

    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_connected || _socket == null) return;

      final now = DateTime.now();
      final diff = now.difference(_lastPongTime ?? now);

      if (diff.inSeconds > 30) {
        debugPrint('[WebSocket] ⚠️ Keine Pong-Antwort seit ${diff.inSeconds}s — reconnect...');
        _socket?.close();
        _onDisconnected();
        return;
      }

      try {
        _socket!.add(jsonEncode({"type": "ping"}));
      } catch (e) {
        debugPrint('[WebSocket] Ping send error: $e');
      }
    });
  }


  void _onMessage(dynamic message) async {
    try {
      Map<String, dynamic> rawData = jsonDecode(message.toString());
      Uint8List? key = WebSocketService().sessionKey;
  
      if (key == null) return;
  
      if (rawData["type"] == "enc") {
        String msg = await WebSocketService().decryptAES(key, rawData);
        Map<String, dynamic> data = jsonDecode(msg);

        final String userId = await secureStorage.getToken("userId");

        if (data["header"] == "session_key_response" && data["status"] == "success") {
          if (await PreferencesUtils().getBool("setupComplete") == false) {
            setReady(true);
            debugPrint("[WebSocket] Setup not complete, skipping auth. -- ready");
            return;
          }

          final authToken = await secureStorage.getToken("authToken");

          if (authToken == "") {
            signout();
            return;
          }

          _sendDirect(jsonEncode({
            "header": "auth",
            "body": {
              "userId": userId,
              "token": authToken,
            }
          }));
        }

        else if (data["header"] == "session_key_response" && data["status"] == "failed") {
          if (_socket != null) {
            await _socket!.close();
            _socket = null;

            _connected = false;
            _connecting = false;

            debugPrint("[WebSocket] Encryption setup failed, reconnecting...");
          }
        }

        else if (data["header"] == "auth_response" && data["status"] == "valid") {
          setReady(true);
        }

        else if (data["header"] == "auth_response" && data["status"] == "token_invalid") {
          final refreshToken = await secureStorage.getToken("refreshToken");
          
          if (refreshToken == "") {
            signout();
            return;
          }

          _sendDirect(jsonEncode({
            "header": "refresh",
            "body": {
              "userId": userId,
              "token": refreshToken,
            }
          }));
        }

        else if (data["header"] == "auth_response" && data["status"] == "user_invalid" || data["header"] == "refresh_response" && data["status"] == "user_invalid") {
          signout();
          return;
        }

        else if (data["header"] == "refresh_response" && data["status"] == "valid") {
          final String newAuthToken = data["body"]["authToken"];
          secureStorage.saveToken("authToken", newAuthToken);

          _sendDirect(jsonEncode({
            "header": "auth",
            "body": {
              "userId": userId,
              "token": newAuthToken,
            }
          }));
        }

        else if (data["header"] == "force_signout") {
          signout();
          return;
        }

        else {
          onMessage?.call(data, _ref);
        }
      }
    }

    catch (error) {
      debugPrint("error: ${error.toString()}");
      debugPrintStack();
    }
  }

  void _onDisconnected() {
    if (_forceClosed) return;
    if (!_connected) return;

    _connected = false;
    _socket = null;

    debugPrint('[WebSocket] Connection lost.');
    _startReconnectLoop();
  }

  void _startReconnectLoop() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_forceClosed) return;

    debugPrint('[WebSocket] Starting reconnect loop...');

    _reconnectTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_connected || _connecting || _forceClosed) return;

      debugPrint('[WebSocket] Reconnect attempt...');
      await connect();
    });
  }

  void _stopReconnectLoop() {
    if (_reconnectTimer?.isActive ?? false) {
      _reconnectTimer!.cancel();
      debugPrint('[WebSocket] Reconnect loop stopped.');
    }

    _reconnectTimer = null;
  }

  Future<void> sendMessage(String message) async {
    if (!_connected && _forceClosed) {
      debugPrint('[WebSocket] Force closed connection, ignoring message.');
      showWebsocketErrorSnackbar();
      return;
    }

    else if (_connected && !_ready && await PreferencesUtils().getBool("setupComplete") == false) {
      debugPrint('[WebSocket] Not setup, skipping auth.');
    }

    else if (!_ready || ( !_connected && !_forceClosed) ) {
      debugPrint('[WebSocket] Not ready, queuing message.');
    
      if (!_messageQueue.contains(message)) {
        _messageQueue.addLast(message);
        debugPrint('[WebSocket] Message added to queue.');
      } else {
        debugPrint('[WebSocket] Duplicate message detected, skipping.');
      }

      return;
    }

    _sendDirect(message);
  }

  Future<void> _sendDirect(String message) async {
    if (_socket == null || !_connected) {
      debugPrint('[WebSocket] No active connection.');
      return;
    }

    try {
      final Map<String, dynamic> encrypted = await encryptAES(_sessionKey!, message);

      final data = jsonEncode({
        "type": "enc",
        "iv": encrypted["iv"],
        "data": encrypted["data"],
        "tag": encrypted["tag"]
      });

      _socket!.add(data);
      debugPrint("sent: $message");
    } catch (e) {
      debugPrint('[WebSocket] Failed to send message: $e');
      showWebsocketErrorSnackbar();
    }
  }

  Future<void> close() async {
    _forceClosed = true;
    _stopReconnectLoop();

    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }

    _connected = false;
    _connecting = false;

    debugPrint('[WebSocket] Connection closed by user.');
  }
}
*/