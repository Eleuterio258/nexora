library;

abstract class LocalStore {
  /// Grava [value] associado a [key]. Sobrescreve se já existir.
  Future<void> write(String key, String value);

  /// Lê o valor de [key]; devolve `null` se não existir.
  Future<String?> read(String key);

  /// Remove a entrada de [key]. Silencioso se não existir.
  Future<void> delete(String key);

  /// Remove todas as entradas geridas por este store.
  Future<void> deleteAll();

  /// Devolve todas as entradas disponíveis neste store.
  Future<Map<String, String>> readAll();

  /// `true` se [key] existir e não for nulo/vazio.
  Future<bool> containsKey(String key);
}
