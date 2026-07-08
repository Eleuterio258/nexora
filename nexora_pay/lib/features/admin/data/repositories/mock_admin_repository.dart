import '../models/api_call.dart';
import '../models/api_key.dart';
import '../models/audit_log.dart';
import '../models/dashboard_summary.dart';
import '../models/limit_policy.dart';
import '../models/merchant.dart';
import '../models/provider.dart';
import '../models/team_member.dart';
import 'admin_repository.dart';

class MockAdminRepository implements AdminRepository {
  final List<Merchant> _merchants = [
    Merchant(
      id: 'm1',
      name: 'Loja Virtual Exemplo',
      email: 'geral@lojaexemplo.co.mz',
      phone: '+258 84 123 4567',
      status: MerchantStatus.active,
      createdAt: DateTime(2026, 6, 15),
      nif: '400123456',
      address: 'Maputo, Av. Julius Nyerere',
    ),
    Merchant(
      id: 'm2',
      name: 'Supermercado Bom Preço',
      email: 'contabilidade@bompreco.co.mz',
      phone: '+258 86 987 6543',
      status: MerchantStatus.pending,
      createdAt: DateTime(2026, 7, 1),
      nif: '400987654',
    ),
    Merchant(
      id: 'm3',
      name: 'Restaurante Sabor Moçambicano',
      email: 'reservas@sabormz.co.mz',
      phone: '+258 87 456 7890',
      status: MerchantStatus.suspended,
      createdAt: DateTime(2026, 5, 20),
    ),
  ];

  final List<ApiKey> _apiKeys = [
    ApiKey(
      id: 'k1',
      merchantId: 'm1',
      merchantName: 'Loja Virtual Exemplo',
      type: ApiKeyType.public,
      status: ApiKeyStatus.active,
      prefix: 'pk_live_8a3f...',
      createdAt: DateTime(2026, 6, 15),
      lastUsedAt: DateTime(2026, 7, 6, 14, 30),
    ),
    ApiKey(
      id: 'k2',
      merchantId: 'm1',
      merchantName: 'Loja Virtual Exemplo',
      type: ApiKeyType.private,
      status: ApiKeyStatus.active,
      prefix: 'sk_live_****',
      createdAt: DateTime(2026, 6, 15),
      lastUsedAt: DateTime(2026, 7, 6, 14, 32),
    ),
    ApiKey(
      id: 'k3',
      merchantId: 'm2',
      merchantName: 'Supermercado Bom Preço',
      type: ApiKeyType.public,
      status: ApiKeyStatus.active,
      prefix: 'pk_test_2b9c...',
      createdAt: DateTime(2026, 7, 1),
    ),
  ];

  final List<LimitPolicy> _limits = [
    LimitPolicy(
      id: 'l1',
      merchantId: 'm1',
      merchantName: 'Loja Virtual Exemplo',
      maxRequestsPerSecond: 10,
      maxRequestsPerDay: 10000,
      updatedAt: DateTime(2026, 6, 20),
    ),
    LimitPolicy(
      id: 'l2',
      merchantId: 'm2',
      merchantName: 'Supermercado Bom Preço',
      maxRequestsPerSecond: 5,
      maxRequestsPerDay: 5000,
      updatedAt: DateTime(2026, 7, 1),
    ),
  ];

  final List<PaymentProvider> _providers = [
    PaymentProvider(
      id: 'p1',
      name: 'M-Pesa',
      status: ProviderStatus.active,
      icon: 'payments',
      description: 'Pagamentos via M-Pesa Moçambique',
    ),
    PaymentProvider(
      id: 'p2',
      name: 'eMola',
      status: ProviderStatus.inactive,
      icon: 'account_balance_wallet',
      description: 'Em integração futura',
    ),
    PaymentProvider(
      id: 'p3',
      name: 'mKesh',
      status: ProviderStatus.inactive,
      icon: 'wallet',
      description: 'Em integração futura',
    ),
    PaymentProvider(
      id: 'p4',
      name: 'Cartões Visa/Mastercard',
      status: ProviderStatus.maintenance,
      icon: 'credit_card',
      description: 'Processamento de cartões',
    ),
  ];

  final List<ApiCall> _apiCalls = [
    ApiCall(
      id: 'c1',
      merchantId: 'm1',
      merchantName: 'Loja Virtual Exemplo',
      method: 'POST',
      endpoint: '/v1/payments',
      statusCode: 200,
      timestamp: DateTime(2026, 7, 6, 15, 10),
    ),
    ApiCall(
      id: 'c2',
      merchantId: 'm2',
      merchantName: 'Supermercado Bom Preço',
      method: 'GET',
      endpoint: '/v1/status',
      statusCode: 401,
      timestamp: DateTime(2026, 7, 6, 15, 8),
      errorMessage: 'Chave de acesso inválida',
    ),
    ApiCall(
      id: 'c3',
      merchantId: 'm1',
      merchantName: 'Loja Virtual Exemplo',
      method: 'POST',
      endpoint: '/v1/refunds',
      statusCode: 201,
      timestamp: DateTime(2026, 7, 6, 15, 5),
    ),
  ];

  final List<AuditLog> _auditLogs = [
    AuditLog(
      id: 'a1',
      userId: 'u1',
      userName: 'Carlos Admin',
      action: 'Aprovou comerciante',
      target: 'Loja Virtual Exemplo',
      details: 'Comerciante m1 aprovado e ativado',
      timestamp: DateTime(2026, 7, 6, 10, 0),
    ),
    AuditLog(
      id: 'a2',
      userId: 'u1',
      userName: 'Carlos Admin',
      action: 'Gerou chave privada',
      target: 'Loja Virtual Exemplo',
      details: 'Nova chave privada gerada',
      timestamp: DateTime(2026, 7, 6, 10, 5),
    ),
    AuditLog(
      id: 'a3',
      userId: 'u2',
      userName: 'Ana Suporte',
      action: 'Revogou chave',
      target: 'Restaurante Sabor Moçambicano',
      details: 'Chave k4 revogada por suspeita de exposição',
      timestamp: DateTime(2026, 7, 5, 16, 45),
    ),
  ];

  final List<TeamMember> _team = [
    TeamMember(
      id: 'u1',
      name: 'Carlos Admin',
      email: 'carlos@nexora.co.mz',
      role: TeamRole.admin,
      isActive: true,
      joinedAt: DateTime(2025, 1, 10),
    ),
    TeamMember(
      id: 'u2',
      name: 'Ana Suporte',
      email: 'ana@nexora.co.mz',
      role: TeamRole.support,
      isActive: true,
      joinedAt: DateTime(2025, 3, 22),
    ),
    TeamMember(
      id: 'u3',
      name: 'João Visualizador',
      email: 'joao@nexora.co.mz',
      role: TeamRole.viewer,
      isActive: false,
      joinedAt: DateTime(2025, 6, 1),
    ),
  ];

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return DashboardSummary(
      transactionsToday: 347,
      totalVolumeToday: 2458000,
      activeMerchants: _merchants.where((m) => m.status == MerchantStatus.active).length,
      totalErrors: 12,
      recentActivity: [
        DashboardActivity(
          id: 'act1',
          title: 'Pagamento aprovado',
          subtitle: 'Loja Virtual Exemplo — 12.500 MT',
          timestamp: DateTime(2026, 7, 6, 15, 10),
        ),
        DashboardActivity(
          id: 'act2',
          title: 'Erro de autenticação',
          subtitle: 'Supermercado Bom Preço — 401',
          timestamp: DateTime(2026, 7, 6, 15, 8),
        ),
        DashboardActivity(
          id: 'act3',
          title: 'Comerciante aprovado',
          subtitle: 'Restaurante Sabor Moçambicano',
          timestamp: DateTime(2026, 7, 6, 14, 50),
        ),
      ],
    );
  }

  @override
  Future<List<Merchant>> getMerchants() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_merchants);
  }

  @override
  Future<Merchant> updateMerchantStatus(String id, MerchantStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _merchants.indexWhere((m) => m.id == id);
    if (index < 0) throw Exception('Comerciante não encontrado');
    _merchants[index] = _merchants[index].copyWith(status: status);
    return _merchants[index];
  }

  @override
  Future<List<ApiKey>> getApiKeys() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_apiKeys);
  }

  @override
  Future<ApiKey> generateApiKey({
    required String merchantId,
    required ApiKeyType type,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final merchant = _merchants.firstWhere((m) => m.id == merchantId);
    final prefix = type == ApiKeyType.public ? 'pk_live_' : 'sk_live_';
    final value = '$prefix${DateTime.now().millisecondsSinceEpoch}';
    final key = ApiKey(
      id: 'k${_apiKeys.length + 1}',
      merchantId: merchantId,
      merchantName: merchant.name,
      type: type,
      status: ApiKeyStatus.active,
      prefix: '${value.substring(0, 12)}...',
      createdAt: DateTime.now(),
      value: value,
    );
    _apiKeys.add(key);
    return key;
  }

  @override
  Future<void> revokeApiKey(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _apiKeys.indexWhere((k) => k.id == id);
    if (index < 0) throw Exception('Chave não encontrada');
    _apiKeys[index] = ApiKey(
      id: _apiKeys[index].id,
      merchantId: _apiKeys[index].merchantId,
      merchantName: _apiKeys[index].merchantName,
      type: _apiKeys[index].type,
      status: ApiKeyStatus.revoked,
      prefix: _apiKeys[index].prefix,
      createdAt: _apiKeys[index].createdAt,
      lastUsedAt: _apiKeys[index].lastUsedAt,
    );
  }

  @override
  Future<List<LimitPolicy>> getLimitPolicies() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_limits);
  }

  @override
  Future<LimitPolicy> updateLimitPolicy(LimitPolicy policy) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _limits.indexWhere((l) => l.id == policy.id);
    if (index < 0) throw Exception('Política não encontrada');
    _limits[index] = policy;
    return policy;
  }

  @override
  Future<List<PaymentProvider>> getProviders() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_providers);
  }

  @override
  Future<PaymentProvider> updateProviderStatus(
    String id,
    ProviderStatus status,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _providers.indexWhere((p) => p.id == id);
    if (index < 0) throw Exception('Provedor não encontrado');
    _providers[index] = PaymentProvider(
      id: _providers[index].id,
      name: _providers[index].name,
      status: status,
      icon: _providers[index].icon,
      description: _providers[index].description,
    );
    return _providers[index];
  }

  @override
  Future<List<ApiCall>> getApiCalls() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_apiCalls);
  }

  @override
  Future<List<AuditLog>> getAuditLogs() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_auditLogs);
  }

  @override
  Future<List<TeamMember>> getTeamMembers() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_team);
  }
}
