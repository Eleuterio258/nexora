abstract class ILocalSecureStorege {
  Future<V?> read<V>(String key);
  Future<void> write<V>(String key, V value);
  Future<bool> contains(String key);
  Future<void> clean();
  Future<void> remove(String key);
}
