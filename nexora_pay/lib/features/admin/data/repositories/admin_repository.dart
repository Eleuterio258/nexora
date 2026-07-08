import '../models/api_call.dart';
import '../models/api_key.dart';
import '../models/audit_log.dart';
import '../models/dashboard_summary.dart';
import '../models/limit_policy.dart';
import '../models/merchant.dart';
import '../models/provider.dart';
import '../models/team_member.dart';

abstract class AdminRepository {
  Future<DashboardSummary> getDashboardSummary();

  Future<List<Merchant>> getMerchants();
  Future<Merchant> updateMerchantStatus(String id, MerchantStatus status);

  Future<List<ApiKey>> getApiKeys();
  Future<ApiKey> generateApiKey({
    required String merchantId,
    required ApiKeyType type,
  });
  Future<void> revokeApiKey(String id);

  Future<List<LimitPolicy>> getLimitPolicies();
  Future<LimitPolicy> updateLimitPolicy(LimitPolicy policy);

  Future<List<PaymentProvider>> getProviders();
  Future<PaymentProvider> updateProviderStatus(
    String id,
    ProviderStatus status,
  );

  Future<List<ApiCall>> getApiCalls();

  Future<List<AuditLog>> getAuditLogs();

  Future<List<TeamMember>> getTeamMembers();
}
