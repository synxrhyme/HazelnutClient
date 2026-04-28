import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hazelnut_shared/auth_service.dart';
import 'package:hazelnut_shared/preferences_service.dart';
import 'package:hazelnut_shared/secure_storage_service.dart';
import 'package:hazelnut_shared/database_service.dart';
import 'package:hazelnut_shared/websocket_bus.dart';

import 'package:hazelnut_shared/websocket_service.dart';
import 'package:mlkem_native/mlkem_native.dart';
import 'secure_storage_service.dart';
import 'preferences_service.dart';
import 'encryption_util_service.dart';

class WebSocketServiceImpl implements WebSocketService {
  final SecureStorageService secureStorage;
  final PreferencesService preferences;
  final WebSocketBus webSocketBus;

  final DatabaseService databaseService;

  WebSocketServiceImpl({
    required this.webSocketBus,
    required this.secureStorage,
    required this.preferences,
    required this.databaseService,
  });

  static Future<WebSocketService> create({
    required WebSocketBus webSocketBus,
    required SecureStorageService secureStorage,
    required PreferencesService preferences,
    required DatabaseService databaseService,
  }) async {
    final svc = WebSocketServiceImpl(
      webSocketBus: webSocketBus,
      secureStorage: secureStorage,
      preferences: preferences,
      databaseService: databaseService,
    );

    return svc;
  }

  @override
  void Function(Map<String, dynamic>, dynamic)? onMessage;

  MLKEM768 mlkem = MLKEM768();
  KeyPair? mlkemKeyPair;

  crypto.KeyPair? _ed25519KeyPair;

  WebSocket? _socket;
  String? _url;

  Uint8List? _sessionKey;
  Uint8List? get sessionKey => _sessionKey;

  bool _forceClosed = false;
  bool _connected = false;
  bool _connecting = false;

  @override
  bool get isConnected => _connected;

  final Queue<String> _messageQueue = Queue<String>();
  bool _ready = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  DateTime? _lastPongTime;

  @override
  void setUrl(String url) => _url = url;

  @override
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

      await _initKeys();

      _socket!.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (error) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (_) {
      _connected = false;
      _connecting = false;
      _startReconnectLoop();
    }
  }

  @override
  Future<void> sendMessageRaw(String raw) async {
    if (!_connected || !_ready || _forceClosed) {
      if (!_messageQueue.contains(raw)) _messageQueue.addLast(raw);
      return;
    }

    await _sendDirect(raw);
  }

  Future<void> _initKeys() async {
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
  }

  void _startPing() {
    _pingTimer?.cancel();
    _lastPongTime = DateTime.now();

    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
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
    final raw = message.toString();
    Map<String, dynamic> rawData = jsonDecode(raw);

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
  }

  void _handleDecrypted(Map<String, dynamic> data) async {
    final String userId = await secureStorage.getToken("userId");
    final theme = Theme.of(rootScaffoldMessengerKey.currentContext!).extension<CustomColors>()!;

    switch (data["header"]) {
      case "handshake_response": {
        if (data["body"]["status"] == "success") {
          debugPrint("[WebSocket] Handshake erfolgreich, Verbindung gesichert");

          if (await preferences.getBool("setupComplete") != true) {
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
            webSocketBus.emit('SHOW_SNACKBAR', {
              'title': 'Auth-Token nicht gefunden',
              'type': 'error',
              'heightOffset': 50,
            });
            showAnimatedSnackbarGlobal(
              icon: Icons.error_outline_rounded,
              color1: theme.warning.shade500!,
              color2: theme.warning.shade400!,
              title: "Auth-Token nicht gefunden",
              heightOffset: 50,
            );

            webSocketBus.emit("SIGNOUT", null);
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

            webSocketBus.emit("SIGNOUT", null);
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

          webSocketBus.emit("SIGNOUT", null);
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

          webSocketBus.emit("SIGNOUT", null);
        }

        break;
      }

      case "force_signout": { 
        webSocketBus.emit("SIGNOUT", null);
        
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
    if (_socket == null || !_connected || _sessionKey == null) return;
    final encrypted = await encryptAES(_sessionKey!, raw);
    _socket!.add(jsonEncode(encrypted));
  }

  @override
  Future<void> close(bool forceClose) async {
    _forceClosed = forceClose;
    if (forceClose) _stopReconnectLoop();
    _pingTimer?.cancel();

    await _socket?.close();
    _socket = null;
    _connected = false;
    _connecting = false;
  }

  @override
  void refreshForAction(Map<String, dynamic> action) {
    // Logik für refresh, evtl. secureStorage verwenden
  }
}