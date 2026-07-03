import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'i_local_storage.dart';

class SecureLocalStorageImpl implements ILocalStorage {
  SecureLocalStorageImpl()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<V?> read<V>(String key) async {
    final value = await _storage.read(key: key);
    return value != null ? value as V : null;
  }

  @override
  Future<void> write<V>(String key, V value) async {
    await _storage.write(key: key, value: value.toString());
  }

  @override
  Future<bool> contains(String key) async {
    return await _storage.read(key: key) != null;
  }

  @override
  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
