import 'dart:ffi';
import 'package:ffi/ffi.dart';

late final DynamicLibrary _liboqs;
late final OqsKemNewDart oqsKemNew;
late final OqsKemKeypairDart oqsKemKeypair;
late final OqsKemEncapsulateDart oqsKemEncapsulate;
late final OqsKemDecapsulateDart oqsKemDecapsulate;
late final OqsKemFreeDart oqsKemFree;

// --- Typedefs für liboqs-Funktionen ---
typedef OqsKemNewNative = Pointer<Void> Function(Pointer<Utf8> method_name);
typedef OqsKemNewDart = Pointer<Void> Function(Pointer<Utf8> method_name);

// OQS_KEM_keypair
typedef OqsKemKeypairNative = Int32 Function(
    Pointer<Void> kem,
    Pointer<Uint8> public_key,
    Pointer<Uint8> secret_key,
);
typedef OqsKemKeypairDart = int Function(
    Pointer<Void> kem,
    Pointer<Uint8> public_key,
    Pointer<Uint8> secret_key,
);

// OQS_KEM_encapsulate
typedef OqsKemEncapsulateNative = Int32 Function(
    Pointer<Void> kem,
    Pointer<Uint8> ciphertext,
    Pointer<Uint8> shared_secret,
    Pointer<Uint8> public_key,
);
typedef OqsKemEncapsulateDart = int Function(
    Pointer<Void> kem,
    Pointer<Uint8> ciphertext,
    Pointer<Uint8> shared_secret,
    Pointer<Uint8> public_key,
);

// OQS_KEM_decapsulate
typedef OqsKemDecapsulateNative = Int32 Function(
    Pointer<Void> kem,
    Pointer<Uint8> shared_secret,
    Pointer<Uint8> ciphertext,
    Pointer<Uint8> secret_key,
);
typedef OqsKemDecapsulateDart = int Function(
    Pointer<Void> kem,
    Pointer<Uint8> shared_secret,
    Pointer<Uint8> ciphertext,
    Pointer<Uint8> secret_key,
);

// OQS_KEM_free
typedef OqsKemFreeNative = Void Function(Pointer<Void> kem);
typedef OqsKemFreeDart = void Function(Pointer<Void> kem);

void initLibOqs(dynamic _) {
  _liboqs = DynamicLibrary.open("liboqs.so");

  oqsKemNew = _liboqs
      .lookup<NativeFunction<OqsKemNewNative>>('OQS_KEM_new')
      .asFunction();

  oqsKemKeypair = _liboqs
      .lookup<NativeFunction<OqsKemKeypairNative>>('OQS_KEM_keypair')
      .asFunction();

  oqsKemEncapsulate = _liboqs
      .lookup<NativeFunction<OqsKemEncapsulateNative>>('OQS_KEM_encaps')
      .asFunction();

  oqsKemDecapsulate = _liboqs
      .lookup<NativeFunction<OqsKemDecapsulateNative>>('OQS_KEM_decaps')
      .asFunction();

  oqsKemFree = _liboqs
      .lookup<NativeFunction<OqsKemFreeNative>>('OQS_KEM_free')
      .asFunction();
}

// --- Hilfsfunktionen für Dart ---
Pointer<Void> createKem(String algorithmName) {
  return oqsKemNew(algorithmName.toNativeUtf8());
}

int generateKeyPair(Pointer<Void> kem, Pointer<Uint8> publicKey, Pointer<Uint8> secretKey) {
  return oqsKemKeypair(kem, publicKey, secretKey);
}

// Weitere Hilfsfunktionen für encapsulate/decapsulate hier...