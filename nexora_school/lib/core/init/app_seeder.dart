import '../local/local_storage/i_local_storage.dart';

class AppSeeder {
  const AppSeeder(this._storage);

  final ILocalStorage _storage;

  Future<void> seed() async {}

  Future<void> clear() async {
    await _storage.clear();
  }
}
