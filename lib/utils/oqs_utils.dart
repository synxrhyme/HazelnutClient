import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:hazelnut/utils/oqs.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/hkdf.dart';

class OqsUtils {
  OqsUtils._internal();
  static final OqsUtils _instance = OqsUtils._internal();

  factory OqsUtils() {
    return _instance;
  }

  Uint8List? _publicKey;
  Uint8List? _secretKey;

  Uint8List? get publicKey => _publicKey;
  Uint8List? get secretKey => _secretKey;

  Map<String, Uint8List>? genKyberPair() {
    final publicKeyPtr = malloc.allocate<Uint8>(1568);
    final secretKeyPtr = malloc.allocate<Uint8>(3168);

    final kem = createKem('Kyber1024');
    final result = generateKeyPair(kem, publicKeyPtr, secretKeyPtr);

    if (result != 0) {
      print('Fehler bei der Schlüsselgenerierung: $result');
      return null;
    }

    // Pointer dereferenzieren
    final publicKey = Uint8List.fromList(publicKeyPtr.asTypedList(1568));
    final secretKey = Uint8List.fromList(secretKeyPtr.asTypedList(3168));

    _publicKey = publicKey;
    _secretKey = secretKey;

    malloc.free(publicKeyPtr);
    malloc.free(secretKeyPtr);
    oqsKemFree(kem);

    return {
      'publicKey': publicKey,
      'secretKey': secretKey,
    };
  }

  Uint8List decapsulate(Uint8List secretKey, Uint8List ciphertext) {
    final kem = createKem('Kyber1024');
    final sharedSecretPtr = malloc.allocate<Uint8>(32);
    final secretKeyPtr = malloc.allocate<Uint8>(3168);
    final ciphertextPtr = malloc.allocate<Uint8>(1568);

    secretKeyPtr.asTypedList(3168).setAll(0, secretKey);
    ciphertextPtr.asTypedList(1568).setAll(0, ciphertext);

    final result = oqsKemDecapsulate(
      kem,
      sharedSecretPtr,
      ciphertextPtr,
      secretKeyPtr,
    );

    if (result != 0) {
      throw Exception('Fehler bei der Decapsulation: $result');
    }

    final sharedSecret = sharedSecretPtr.asTypedList(32);

    malloc.free(secretKeyPtr);
    malloc.free(ciphertextPtr);
    malloc.free(sharedSecretPtr);
    oqsKemFree(kem);

    return sharedSecret;
  }

  Uint8List deriveAesKey(Uint8List sharedSecret, {String context = 'AES-256-Key', int length = 32}) {
    final digest = SHA256Digest();

    final hkdf = HKDFKeyDerivator(digest)
      ..init(HkdfParameters(sharedSecret, length,  ""));

    final output = Uint8List(length);
    hkdf.deriveKey(
      Uint8List.fromList(context.codeUnits),
      0,
      output,
      0
    );

    return output;
  }
}