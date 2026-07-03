import 'package:hive_flutter/hive_flutter.dart';
import '../local_store.dart';

// Implementacao usando Hive — adequada para cache nao sensivel (vagas, candidaturas).
// NAO usar para tokens JWT ou credenciais (usar SecureLocalStore para esses casos).
// Para activar: trocar SecureLocalStore por HiveLocalStore no injection_container.
class HiveLocalStore implements LocalStore {
  final Box<String> _box;

  const HiveLocalStore(this._box);

  static Future<HiveLocalStore> open(String boxName) async {
    final box = await Hive.openBox<String>(boxName);
    return HiveLocalStore(box);
  }

  @override
  Future<void> write(String key, String value) async =>
      _box.put(key, value);

  @override
  Future<String?> read(String key) async => _box.get(key);

  @override
  Future<void> delete(String key) async => _box.delete(key);

  @override
  Future<void> deleteAll() async => _box.clear();

  @override
  Future<Map<String, String>> readAll() async =>
      Map<String, String>.from(_box.toMap().cast<String, String>());

  @override
  Future<bool> containsKey(String key) async => _box.containsKey(key);
}
