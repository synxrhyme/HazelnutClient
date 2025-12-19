import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:hazelnut/utils/oqs.dart';
import 'package:pointycastle/export.dart';

class OqsUtils {
  OqsUtils._internal();
  static final OqsUtils _instance = OqsUtils._internal();

  factory OqsUtils() {
    return _instance;
  }

  Uint8List? publicKey;
  Uint8List? secretKey;

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

  static Uint8List deriveAesKey(Uint8List password, String salt, int iterations, int derivedKeyLength) {
    final saltBytes = utf8.encode(salt);

    final params = Pbkdf2Parameters(Uint8List.fromList(saltBytes), iterations, derivedKeyLength);
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA512Digest(), 64));

    pbkdf2.init(params);
    return pbkdf2.process(Uint8List.fromList(password));
  }
}

Map<String, Uint8List>? genKyberPair(dynamic _) {
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

  malloc.free(publicKeyPtr);
  malloc.free(secretKeyPtr);
  oqsKemFree(kem);

  return {
    'publicKey': publicKey,
    'secretKey': secretKey,
  };
}