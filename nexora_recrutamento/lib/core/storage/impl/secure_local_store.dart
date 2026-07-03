import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../local_store.dart';

// Implementação activa — usa flutter_secure_storage (dados cifrados no keystore).
// Ideal para tokens JWT e credenciais.
class SecureLocalStore implements LocalStore {
  final FlutterSecureStorage _storage;

  const SecureLocalStore([
    FlutterSecureStorage? storage,
  ]) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}
