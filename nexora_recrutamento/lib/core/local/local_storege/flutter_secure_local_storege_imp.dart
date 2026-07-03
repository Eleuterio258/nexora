import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'i_local_storege.dart';

class FlutterSecureLocalStoregeImp implements ILocalSecureStorege {
  late final FlutterSecureStorage _secureStorage;

  FlutterSecureLocalStoregeImp() {
    _secureStorage = const FlutterSecureStorage();
  }
  @override
  Future<void> clean() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<bool> contains(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null;
  }

  @override
  Future<V?> read<V>(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null ? value as V : null;
  }

  @override
  Future<void> remove(String key) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> write<V>(String key, V value) async {
    await _secureStorage.write(key: key, value: value.toString());
  }
}
