import 'package:uuid/uuid.dart';

import '../local/local_storege/i_local_storege.dart';

class DeviceIdProvider {
  static const _key = 'device_id';

  final ILocalSecureStorege _storage;

  DeviceIdProvider(this._storage);

  Future<String> getOrCreate() async {
    final existing = await _storage.read<String>(_key);
    if (existing != null) return existing;

    final generated = const Uuid().v4();
    await _storage.write(_key, generated);
    return generated;
  }
}
