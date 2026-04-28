abstract class PreferencesService {
  Future<void> reload();

  Future<bool?> getBool(String key);
  Future<void>  setBool(String key, bool value);

  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);
}