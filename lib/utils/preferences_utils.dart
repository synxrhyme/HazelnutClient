import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtils {
  PreferencesUtils._internal();
  static final PreferencesUtils _instance = PreferencesUtils._internal();
  factory PreferencesUtils() => _instance;

  SharedPreferences? prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> reload() async {
    await prefs?.reload();
  }

  //Future<void>    setString(String key, String value) async => await prefs?.setString(key, value);
  //Future<String?> getString(String key)               async => prefs?.getString(key);

  Future<void>    setBool(String key, bool value)     async => await prefs?.setBool(key, value);
  Future<bool?>   getBool(String key)                 async => prefs?.getBool(key);

  Future<void>    setInt(String key, int value)       async => prefs?.setInt(key, value);
  Future<int?>    getInt(String key)                  async => prefs?.getInt(key);
}