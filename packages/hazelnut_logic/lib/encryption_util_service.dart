import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:hazelnut_logic/websocket_service.dart';
import "package:pointycastle/export.dart" show HKDFKeyDerivator, HkdfParameters, RSAPublicKey, SHA256Digest;

extension AesHelper on WebSocketServiceImpl {
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

  Uint8List deriveAesKey(Uint8List sharedSecret, {Uint8List? salt, Uint8List? info}) {
    final hkdf = HKDFKeyDerivator(SHA256Digest());

    final actualSalt = salt ?? Uint8List(32); // 32 Nullbytes für SHA-256
    final actualInfo = info ?? Uint8List.fromList(utf8.encode('mlkem768-hkdf-aes256gcm-v1'));

    hkdf.init(HkdfParameters(
      sharedSecret,
      32,
      actualSalt,
      actualInfo,
    ));

    final output = Uint8List(32);
    hkdf.deriveKey(null, 0, output, 0);
    return output;
  }

  Future<bool> verifyServerCiphertextEd25519(Uint8List ciphertext, Uint8List signature, Uint8List serverPublicKeyBytes, int timestamp) async {
    final algorithm = crypto.Ed25519();
    final publicKey = crypto.SimplePublicKey(serverPublicKeyBytes, type: crypto.KeyPairType.ed25519);
    
    final message = Uint8List.fromList([
      ...ciphertext,
      ...utf8.encode(timestamp.toString()),
    ]);

    return await algorithm.verify(
      message,
      signature: crypto.Signature(signature, publicKey: publicKey),
    );
  }
}