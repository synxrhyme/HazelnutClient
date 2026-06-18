import 'dart:typed_data';

abstract class CryptoService {
  Future<Map<String, dynamic>> encryptAES(Uint8List key, String plaintext);
  Future<String> decryptAES(Uint8List key, Map<String, dynamic> payload);

  Uint8List deriveAesKey(Uint8List sharedSecret, {Uint8List? salt, Uint8List? info});

  Future<bool> verifyServerSignature(
    Uint8List ciphertext,
    Uint8List signature,
    Uint8List serverPubKey,
    int timestamp,
  );
}
