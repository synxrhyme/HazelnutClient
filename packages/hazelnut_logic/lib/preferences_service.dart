import 'package:shared_preferences/shared_preferences.dart';
class PreferencesService {
  final SharedPreferences prefs;
  PreferencesService._(this.prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  Future<void> reload() async {
    await prefs.reload();
  }

  Future<void>    setString(String key, String value) async => await prefs.setString(key, value);
  Future<String?> getString(String key)               async => prefs.getString(key);

  Future<void> setBool(String key, bool value) async => await prefs.setBool(key, value);

  Future<bool?> getBool(String key) async {
    final value = prefs.getBool(key);
    if (value == null && key == "setupComplete") return false;
    return value;
  }

  Future<void> setInt(String key, int value) async => prefs.setInt(key, value);
  Future<int?> getInt(String key) async => prefs.getInt(key);
}