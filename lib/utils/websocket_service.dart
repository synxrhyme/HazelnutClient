import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/theme.dart';
import 'package:hazelnut/utils/database_service.dart';
import "package:hazelnut/utils/encryption_utils.dart";
import 'package:hazelnut/utils/oqs_utils.dart';
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

  Map<String, Uint8List>? kyberKeyPair;

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
      _startPing();

      kyberKeyPair = await compute(genKyberPair, null);
      if (kyberKeyPair == null || kyberKeyPair!["publicKey"] == null || kyberKeyPair!["secretKey"] == null) {
        throw Exception("Fehler bei der Kyber-Schlüsselgenerierung");
      }

      OqsUtils().publicKey = kyberKeyPair!["publicKey"]!;
      OqsUtils().secretKey = kyberKeyPair!["secretKey"]!;

      final data = jsonEncode({
        "type": "kyber_key",
        "publicKey": base64Encode(kyberKeyPair!["publicKey"]!),
        "id": dotenv.get("ID"),
      });

      _socket!.add(data);
      debugPrint("[WebSocket] Kyber-Key gesendet");

      _socket!.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (error) {
          debugPrint('[WebSocket] Error: $error');
          _onDisconnected();
        },
        cancelOnError: false,
      );
    }
    
    catch (e) {
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
      }
      
      catch (e) {
        debugPrint('[WebSocket] Ping send error: $e');
      }
    });
  }

  void _onMessage(dynamic message) async {
    try {
      final msg = message.toString();

      if (msg.contains('"pong"')) {
        _lastPongTime = DateTime.now();
        return;
      }

      Map<String, dynamic> rawData = jsonDecode(msg);

      if (rawData["type"] == "kyber_key_response") {
        if (rawData["status"] != "success") {
          throw Exception("Kyber-Schlüsselaustausch fehlgeschlagen");
        }

        final ciphertext = base64Decode(rawData["body"]["ciphertext"].toString());
        if (OqsUtils().secretKey == null) {
          throw Exception("Kein Kyber-Geheimschlüssel vorhanden");
        }

        debugPrint("ciphertext: ${hexToBytes(toHex(ciphertext))}");

        final sharedSecret = OqsUtils().decapsulate(OqsUtils().secretKey!, ciphertext);
        debugPrint("shared Secret: ${hexToBytes(toHex(sharedSecret))}");

        final aesKey = OqsUtils.deriveAesKey(Uint8List.fromList(sharedSecret), "Hazelnut-PBKDF2-Salt", 100000, 32);
        if (aesKey.length != 32) {
          throw Exception("Ungültige AES-Schlüssellänge: ${aesKey.length}");
        }

        debugPrint("aes key: ${toHex(aesKey)}");
        _sessionKey = aesKey;

        if (await PreferencesUtils().getBool("setupComplete") != true) {
          debugPrint("Setup nicht abgeschlossen, Authentifizierung übersprungen");
          setReady(true);
          _flushQueue();
          return;
        }

        final String userId = await secureStorage.getToken("userId");
        final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

        final authToken = await secureStorage.getToken("authToken");
        if (authToken.isEmpty) {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Auth-Token nicht gefunden",
            heightOffset: 50,
          );

          signout();
          return;
        }

        Future.delayed(const Duration(milliseconds: 500)).then((_) {
          _sendDirect(jsonEncode({
            "header": "auth",
            "body": { "userId": userId, "token": authToken },
          }));
        });
      }

      if (rawData["type"] == "enc") {
        final key = _sessionKey;
        if (key == null) return;

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
    final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

    switch (data["header"]) {
      case "auth_response": {
        if (data["status"] == "valid") {
          setReady(true);
        }
        
        else if (data["status"] == "token_invalid") {
          final refreshToken = await secureStorage.getToken("refreshToken");
          if (refreshToken.isEmpty) {
            showAnimatedSnackbarGlobal(
              icon: Icons.error_outline_rounded,
              color1: theme.warning.shade500!,
              color2: theme.warning.shade400!,
              title: "Refresh-Token nicht gefunden",
              heightOffset: 50,
            );

            signout();
            return;
          }

          _sendDirect(jsonEncode({
            "header": "refresh",
            "body": { "userId": userId, "token": refreshToken },
          }));
        }
        
        else if (data["status"] == "user_invalid") {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Nutzer nicht bekannt",
            heightOffset: 50,
          );

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
            "body": { "userId": userId, "token": newAuthToken },
          }));
        }
        
        else if (data["status"] == "user_invalid") {
          showAnimatedSnackbarGlobal(
            icon: Icons.error_outline_rounded,
            color1: theme.warning.shade500!,
            color2: theme.warning.shade400!,
            title: "Nutzer nicht bekannt",
            heightOffset: 50,
          );

          signout();
        }

        break;
      }

      case "force_signout": { 
        signout();
        
        showAnimatedSnackbarGlobal(
          icon: Icons.info_outline_rounded,
          color1: theme.error.shade500!,
          color2: theme.error.shade500!,
          title: "Du wurdest abgemeldet",
          heightOffset: 50,
        );
        
        break;
      }

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

  void refreshForAction(Map<String, dynamic> action) async {
    final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

    setReady(false);
    sendMessage(jsonEncode(action));

    final String userId       = await secureStorage.getToken("userId");
    final String refreshToken = await secureStorage.getToken("refreshToken");

    if (refreshToken.isEmpty) {
      showAnimatedSnackbarGlobal(
        icon: Icons.error_outline_rounded,
        color1: theme.warning.shade500!,
        color2: theme.warning.shade400!,
        title: "Refresh-Token nicht gefunden",
        heightOffset: 50,
      );

      signout();
      return;
    }

    _sendDirect(jsonEncode({
      "header": "refresh",
      "body": { "userId": userId, "token": refreshToken },
    }));
  }

  Future<void> sendMessage(String message) async {
    if (_forceClosed) {
      final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

      showAnimatedSnackbarGlobal(
        icon: Icons.error_outline_rounded,
        color1: theme.warning.shade500!,
        color2: theme.warning.shade400!,
        title: "Verbindung getrennt",
        heightOffset: 50,
      );

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

  Future<void> _sendDirect(String raw) async {
    if (_socket == null || !_connected) return;

    try {
      final Map<String, dynamic> msg = jsonDecode(raw);
      msg["authToken"] = await secureStorage.getToken("authToken");
      msg["userId"]    = await secureStorage.getToken("userId");
      final String message = jsonEncode(msg);

      final encrypted = await encryptAES(_sessionKey!, message);
      final data = jsonEncode({
        "type": "enc",
        "iv": encrypted["iv"],
        "data": encrypted["data"],
        "tag": encrypted["tag"],
      });

      debugPrint('[WebSocket] Sending message: $message');
      _socket!.add(data);
    }
    
    catch (e) {
      final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;
      
      showAnimatedSnackbarGlobal(
        icon: Icons.error_outline_rounded,
        color1: theme.warning.shade500!,
        color2: theme.warning.shade400!,
        title: "Fehler beim Senden",
        heightOffset: 50,
      );
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

String toHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

Uint8List hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < hex.length; i += 2) {
    result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return result;
}