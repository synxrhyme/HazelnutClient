import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:hazelnut/utils/oqs.dart';

class OqsUtils {
  OqsUtils._internal();
  static final OqsUtils _instance = OqsUtils._internal();

  factory OqsUtils() {
    return _instance;
  }

  late final Uint8List _publicKey;
  late final Uint8List _secretKey;

  Uint8List get publicKey => _publicKey;
  Uint8List get secretKey => _secretKey;

  Map<String, Uint8List>? genKyberPair() {
    final publicKeyPtr = malloc.allocate<Uint8>(1184);
    final secretKeyPtr = malloc.allocate<Uint8>(2400);

    final kem = createKem('Kyber1024');
    final result = generateKeyPair(kem, publicKeyPtr, secretKeyPtr);

    if (result != 0) {
      print('Fehler bei der Schlüsselgenerierung: $result');
      return null;
    }

    // 3. Pointer in Uint8List konvertieren
    final publicKey = publicKeyPtr.asTypedList(1184);
    final secretKey = secretKeyPtr.asTypedList(2400);

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
    final secretKeyPtr = malloc.allocate<Uint8>(2400);
    final ciphertextPtr = malloc.allocate<Uint8>(1088);

    secretKeyPtr.asTypedList(2400).setAll(0, secretKey);
    ciphertextPtr.asTypedList(1088).setAll(0, ciphertext);

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
}