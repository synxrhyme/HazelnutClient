import 'dart:convert';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hazelnut_logic/crypto_service.dart';
import 'package:mlkem_native/mlkem768.dart';

class WebSocketHandshake {
  final CryptoService cryptoService;
  late Function(String) _sendMessage;

  MLKEM768 mlkem = MLKEM768();
  KeyPair? _mlkemKeyPair;
  crypto.KeyPair? _ed25519KeyPair;
  Uint8List? _sessionKey;

  WebSocketHandshake({
    required this.cryptoService,
  });

  void setSendMessage(Function(String) sendMessage) {
    _sendMessage = sendMessage;
  }

  Uint8List? getSessionKey() => _sessionKey;

  void reset() {
    _mlkemKeyPair = null;
    _ed25519KeyPair = null;
    _sessionKey = null;
  }

  Future<void> initiate() async {
    final mlkem = MLKEM768();
    _mlkemKeyPair = mlkem.generateKeyPair();

    if (_mlkemKeyPair == null) {
      throw Exception("Fehler bei der Generierung des MLKEM-Schlüsselpaares");
    }

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final algorithm = crypto.Ed25519();

    final ed25519KeyPair = await algorithm.newKeyPair();
    final ed25519PublicKey = await ed25519KeyPair.extractPublicKey();

    _ed25519KeyPair = ed25519KeyPair;

    final messageToSign = Uint8List.fromList([
      ..._mlkemKeyPair!.publicKey,
      ...utf8.encode(timestamp.toString()),
    ]);

    final signature = await algorithm.sign(messageToSign, keyPair: ed25519KeyPair);
    final idHash = await crypto.Sha256().hash(dotenv.get("ID").codeUnits);

    final data = jsonEncode({
      "type": "key_exchange",
      "publicKey": base64Encode(_mlkemKeyPair!.publicKey),
      "timestamp": timestamp,
      "authPublicKey": base64Encode(ed25519PublicKey.bytes),
      "authSignature": base64Encode(signature.bytes),
      "id": base64Encode(idHash.bytes),
    });

    _sendMessage(data);
    debugPrint("[WebSocket] MLKEM-Key gesendet");
  }

  Future<void> handleResponse(Map<String, dynamic> data) async {
    if (data["status"] != "success") {
      throw Exception("Schlüsselaustausch fehlgeschlagen");
    }

    final ciphertext = base64Decode(data["body"]["ciphertext"].toString());
    final authPublicKey = base64Decode(data["body"]["ed25519PublicKey"].toString());
    final signature = base64Decode(data["body"]["ed25519Signature"].toString());
    final timestamp = int.parse(data["body"]["timestamp"].toString());

    final isVerified = await cryptoService.verifyServerSignature(
      ciphertext,
      signature,
      authPublicKey,
      timestamp,
    );

    if (!isVerified) {
      throw Exception("Die Signatur des Servers konnte nicht verifiziert werden");
    }

    final sharedSecret = mlkem.decapsulate(ciphertext, _mlkemKeyPair!.secretKey);
    _sessionKey = cryptoService.deriveAesKey(sharedSecret);

    debugPrint("[WebSocket] Session Key etabliert");
  }

  Future<void> confirmKey(Map<String, dynamic> data) async {
    if (_sessionKey == null || _ed25519KeyPair == null) {
      throw Exception("Handshake nicht richtig initialisiert");
    }

    final keyHash = await crypto.Sha256().hash(_sessionKey!);
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

    _sendMessage(confirmation);
    debugPrint("[WebSocket] Schlüssel bestätigt");
  }
}
