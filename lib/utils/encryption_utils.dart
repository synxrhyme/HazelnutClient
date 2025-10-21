import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:cryptography/cryptography.dart' as crypto;

import "package:hazelnut/utils/websocket_service.dart";
import "package:pointycastle/export.dart" show RSAPublicKey;

extension AesHelper on WebSocketService {
  Uint8List generateRawAesKey() {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
  }

  Future<RSAPublicKey> fetchServerKey(String url) async {
    final res = await HttpClient().getUrl(Uri.parse(url));
    final response = await res.close();
    final pem = await response.transform(utf8.decoder).join();
    
    final parser = RSAKeyParser();
    return parser.parse(pem) as RSAPublicKey;
  }

  String encryptAesKey(Uint8List rawSessionKey, RSAPublicKey publicKey) {
    final encrypter = Encrypter(RSA(
      publicKey: publicKey,
      encoding: RSAEncoding.OAEP,
      digest: RSADigest.SHA256,
    ));

    final encrypted = encrypter.encryptBytes(rawSessionKey);
    return encrypted.base64;
  }

  Future<Map<String, dynamic>> encryptAES(Uint8List key, String plaintext) async {
    final aes = crypto.AesGcm.with256bits();
    final secretKey = crypto.SecretKey(key);

    final nonce = aes.newNonce();

    final secretBox = await aes.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      "iv": base64Encode(nonce),
      "data": base64Encode(secretBox.cipherText),
      "tag": base64Encode(secretBox.mac.bytes),
    };
  }

  Future<String> decryptAES(Uint8List key, Map<String, dynamic> payload) async {
    final aes = crypto.AesGcm.with256bits();
    final secretKey = crypto.SecretKey(key);

    final secretBox = crypto.SecretBox(
      base64Decode(payload["data"]),
      nonce: base64Decode(payload["iv"]),
      mac: crypto.Mac(base64Decode(payload["tag"])),
    );

    final cleartext = await aes.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(cleartext);
  }
}