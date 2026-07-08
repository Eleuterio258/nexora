enum ApiKeyType { public, private }

enum ApiKeyStatus { active, revoked }

class ApiKey {
  const ApiKey({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.type,
    required this.status,
    required this.prefix,
    required this.createdAt,
    this.lastUsedAt,
    this.value,
  });

  final String id;
  final String merchantId;
  final String merchantName;
  final ApiKeyType type;
  final ApiKeyStatus status;
  final String prefix;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  /// Só preenchido imediatamente após a criação. Nunca armazenado em texto integral.
  final String? value;

  String get typeLabel => switch (type) {
        ApiKeyType.public => 'Pública',
        ApiKeyType.private => 'Privada',
      };

  String get statusLabel => switch (status) {
        ApiKeyStatus.active => 'Ativa',
        ApiKeyStatus.revoked => 'Revogada',
      };
}
