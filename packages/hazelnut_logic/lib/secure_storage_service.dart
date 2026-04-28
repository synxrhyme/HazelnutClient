import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hazelnut_shared/secure_storage_service.dart';

class SecureStorageServiceImpl extends SecureStorageService {
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> saveToken(String key, String token) async {
    await _storage.write(key: key, value: token);
  }

  @override
  Future<String> getToken(String key) async {
    return await _storage.read(key: key) ?? "";
  }

  @override
  Future<void> deleteToken(String key) async {
    await _storage.delete(key: key);
  }
}