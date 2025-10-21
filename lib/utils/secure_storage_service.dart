import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Singleton
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String key, String token) async {
    await _storage.write(key: key, value: token);
  }

  Future<String> getToken(String key) async {
    return await _storage.read(key: key) ?? "";
  }

  Future<void> deleteToken(String key) async {
    await _storage.delete(key: key);
  }
}