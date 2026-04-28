import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:hazelnut/main.dart';
import 'package:hazelnut/theme.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:hazelnut/utils/database_service.dart';
import "package:hazelnut/utils/encryption_utils.dart";
import 'package:hazelnut/utils/preferences_utils.dart';
import 'package:hazelnut/utils/signout.dart';
import 'package:hazelnut/utils/snackbar_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mlkem_native/mlkem_native.dart' show KeyPair, MLKEM768;

class webSocketService {
  late WidgetRef _ref;

  webSocketService._internal();
  static final webSocketService _instance = webSocketService._internal();
  factory webSocketService() => _instance;

  WebSocket? _socket;
  String? _url;

  Uint8List? _sessionKey;
  Uint8List? get sessionKey => _sessionKey;

  MLKEM768 mlkem = MLKEM768();
  KeyPair? mlkemKeyPair;

  crypto.KeyPair? _ed25519KeyPair;

  bool _forceClosed = false;
  bool _connected = false;
  bool _connecting = false;
  bool get isConnected => _connected;

  bool showingError = false;

  Queue<String> _messageQueue = Queue<String>();
  bool _ready = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  DateTime? _lastPongTime;

  void Function(Map<String, dynamic>, WidgetRef)? onMessage;

  void init(WidgetRef ref) => _ref = ref;
  void setUrl(String url)  => _url = url;

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

    try {
      final socket = await WebSocket.connect(_url!).timeout(const Duration(seconds: 9));

      _socket = socket;
      _connected = true;
      _connecting = false;
      _forceClosed = false;

      debugPrint('[WebSocket] Connected.');
      _stopReconnectLoop();
      _startPing();

      final mlkem = MLKEM768();
      mlkemKeyPair = mlkem.generateKeyPair();

      if (mlkemKeyPair == null) {
        throw Exception("Fehler bei der Generierung des MLKEM-Schlüsselpaares");
      }

      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final algorithm = crypto.Ed25519();

      final ed25519KeyPair      = await algorithm.newKeyPair();
      final ed25519PublicKey    = await ed25519KeyPair.extractPublicKey();

      _ed25519KeyPair = ed25519KeyPair;

      final messageToSign = Uint8List.fromList([
        ...mlkemKeyPair!.publicKey,
        ...utf8.encode(timestamp.toString()),
      ]);

      final signature = await algorithm.sign(messageToSign, keyPair: ed25519KeyPair);
      final idHash = await crypto.Sha256().hash(dotenv.get("ID").codeUnits);

      final data = jsonEncode({
        "type": "key_exchange",
        "publicKey": base64Encode(mlkemKeyPair!.publicKey),
        "timestamp": timestamp,
        "authPublicKey": base64Encode(ed25519PublicKey.bytes),
        "authSignature": base64Encode(signature.bytes),
        "id": base64Encode(idHash.bytes),
      });

      _socket!.add(data);
      debugPrint("[WebSocket] MLKEM-Key gesendet");

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
      Map<String, dynamic> rawData = jsonDecode(msg);

      if (rawData["type"] == "pong") {
        _lastPongTime = DateTime.now();
        return;
      }

      if (rawData["type"] == "key_exchange_response") {
        if (rawData["status"] != "success") {
          throw Exception("Schlüsselaustausch fehlgeschlagen");
        }

        final ciphertext    = base64Decode(rawData["body"]["ciphertext"].toString());
        final authPublicKey = base64Decode(rawData["body"]["ed25519PublicKey"].toString());
        final signature     = base64Decode(rawData["body"]["ed25519Signature"].toString());
        final timestamp     = int.parse(rawData["body"]["timestamp"].toString());

        final isVerified = await verifyServerCiphertextEd25519(ciphertext, signature, authPublicKey, timestamp);
        if (isVerified == false) {
          throw Exception("Die Signatur des Servers konnte nicht verifiziert werden");
        }

        final sharedSecret = mlkem.decapsulate(ciphertext, mlkemKeyPair!.secretKey);
        final aesKey = deriveAesKey(sharedSecret);

        _sessionKey = aesKey;
        final keyHash = await crypto.Sha256().hash(aesKey);

        final newTimestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
        final algorithm = crypto.Ed25519();

        final messageToSign = Uint8List.fromList([
          ...keyHash.bytes,
          ...utf8.encode(newTimestamp.toString()),
        ]);

        final newSignature = await algorithm.sign(messageToSign, keyPair: _ed25519KeyPair!);

        final confirmation = jsonEncode({
          "type": "key_confirmation",
          "hash": base64Encode(keyHash.bytes),
          "timestamp": newTimestamp,
          "signature": base64Encode(newSignature.bytes),
        });

        _socket!.add(confirmation);
        debugPrint("[WebSocket] Schlüssel bestätigt");
        return;
      }

      if (rawData["type"] == "enc") {
        if (_sessionKey == null) return;

        final decrypted = await decryptAES(_sessionKey!, rawData);
        final data = jsonDecode(decrypted);


        _handleDecrypted(data);
      }
    } catch (error) {
      debugPrint("error: $error");
    }
  }

  void _handleDecrypted(Map<String, dynamic> data) async {
    final String userId = await secureStorage.getToken("userId");
    final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

    switch (data["header"]) {
      case "handshake_response": {
        if (data["body"]["status"] == "success") {
          debugPrint("[WebSocket] Handshake erfolgreich, Verbindung gesichert");

          if (await PreferencesUtils().getBool("setupComplete") != true) {
            debugPrint("Setup nicht abgeschlossen, Authentifizierung übersprungen");
            setReady(true);
            _flushQueue();

            final infoMsg = jsonEncode({
              "header": "auth",
              "body": {
                "type": "signup"
              },
            });

            _sendDirect(infoMsg);
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
              "body": { 
                "type": "login",
                "userId": userId,
                "token": authToken
              },
            }));
          });
        }
        
        break;
      }

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
            "header": "refresh_request",
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
            "body": { 
              "type": "login",
              "userId": userId,
              "token": newAuthToken
            },
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

  Future<void> sendMessage(String raw) async {
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
      if (!_messageQueue.contains(raw)) {
        _messageQueue.addLast(raw);
      }

      return;
    }

    final Map<String, dynamic> msg = jsonDecode(raw);
    msg["authToken"] = await secureStorage.getToken("authToken");
    msg["userId"]    = await secureStorage.getToken("userId");
    final String message = jsonEncode(msg);

    _sendDirect(message);
  }

  Future<void> sendMessageRaw(String raw) async {
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
      if (!_messageQueue.contains(raw)) {
        _messageQueue.addLast(raw);
      }

      return;
    }

    _sendDirect(raw);
  }

  Future<void> _sendDirect(String raw) async {
    if (_socket == null || !_connected || _sessionKey == null) return;

    try {
      final encrypted = await encryptAES(_sessionKey!, raw);
      final idHash = await crypto.Sha256().hash(dotenv.get("ID").codeUnits);

      final data = jsonEncode({
        "type": "enc",
        "iv": encrypted["iv"],
        "data": encrypted["data"],
        "tag": encrypted["tag"],
        "id": base64Encode(idHash.bytes),
      });

      debugPrint('[WebSocket] Sending message: $raw');
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