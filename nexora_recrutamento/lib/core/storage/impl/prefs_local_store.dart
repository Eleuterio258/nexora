import 'package:shared_preferences/shared_preferences.dart';
import '../local_store.dart';

// Alternativa não cifrada — usa SharedPreferences.
// Adequada para preferências do utilizador (idioma, tema, etc.)
// NÃO usar para tokens JWT ou dados sensíveis.
// Para activar: trocar SecureLocalStore por PrefsLocalStore no injection_container.
class PrefsLocalStore implements LocalStore {
  final SharedPreferences _prefs;

  const PrefsLocalStore(this._prefs);

  static Future<PrefsLocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsLocalStore(prefs);
  }

  @override
  Future<void> write(String key, String value) =>
      _prefs.setString(key, value).then((_) {});

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> delete(String key) => _prefs.remove(key).then((_) {});

  @override
  Future<void> deleteAll() => _prefs.clear().then((_) {});

  @override
  Future<Map<String, String>> readAll() async {
    return {
      for (final key in _prefs.getKeys())
        if (_prefs.getString(key) != null) key: _prefs.getString(key)!,
    };
  }

  @override
  Future<bool> containsKey(String key) async => _prefs.containsKey(key);
}
