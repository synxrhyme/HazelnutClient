import 'package:shared_preferences/shared_preferences.dart';
import 'package:hazelnut_shared/preferences_service.dart';

class PreferencesServiceImpl extends PreferencesService {
  final SharedPreferences prefs;
  PreferencesServiceImpl._(this.prefs);

  static Future<PreferencesServiceImpl> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesServiceImpl._(prefs);
  }

  @override
  Future<void> reload() async {
    await prefs.reload();
  }

  Future<void>    setString(String key, String value) async => await prefs.setString(key, value);
  Future<String?> getString(String key)               async => prefs.getString(key);

  @override
  Future<void> setBool(String key, bool value) async => await prefs.setBool(key, value);

  @override
  Future<bool?> getBool(String key) async {
    final value = prefs.getBool(key);
    if (value == null && key == "setupComplete") return false;
    return value;
  }

  @override
  Future<void> setInt(String key, int value) async => prefs.setInt(key, value);

  @override
  Future<int?> getInt(String key) async => prefs.getInt(key);
}