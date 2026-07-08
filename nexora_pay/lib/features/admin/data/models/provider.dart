enum ProviderStatus { active, inactive, maintenance }

class PaymentProvider {
  const PaymentProvider({
    required this.id,
    required this.name,
    required this.status,
    required this.icon,
    this.description,
  });

  final String id;
  final String name;
  final ProviderStatus status;
  final String icon;
  final String? description;

  String get statusLabel => switch (status) {
        ProviderStatus.active => 'Ativo',
        ProviderStatus.inactive => 'Inativo',
        ProviderStatus.maintenance => 'Manutenção',
      };
}
