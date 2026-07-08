enum MerchantStatus { pending, active, suspended }

class Merchant {
  const Merchant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.nif,
    this.address,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final MerchantStatus status;
  final DateTime createdAt;
  final String? nif;
  final String? address;

  String get statusLabel => switch (status) {
        MerchantStatus.pending => 'Pendente',
        MerchantStatus.active => 'Ativo',
        MerchantStatus.suspended => 'Suspenso',
      };

  Merchant copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    MerchantStatus? status,
    DateTime? createdAt,
    String? nif,
    String? address,
  }) {
    return Merchant(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      nif: nif ?? this.nif,
      address: address ?? this.address,
    );
  }
}
