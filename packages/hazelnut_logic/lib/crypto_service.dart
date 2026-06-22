import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:pointycastle/export.dart' show HKDFKeyDerivator, HkdfParameters, SHA256Digest;

class CryptoService {
  @override
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

  @override
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

  @override
  Uint8List deriveAesKey(Uint8List sharedSecret, {Uint8List? salt, Uint8List? info}) {
    final hkdf = HKDFKeyDerivator(SHA256Digest());

    final actualSalt = salt ?? Uint8List(32);
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

  @override
  Future<bool> verifyServerSignature(
    Uint8List ciphertext,
    Uint8List signature,
    Uint8List serverPubKey,
    int timestamp,
  ) async {
    final algorithm = crypto.Ed25519();
    final publicKey = crypto.SimplePublicKey(serverPubKey, type: crypto.KeyPairType.ed25519);

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
