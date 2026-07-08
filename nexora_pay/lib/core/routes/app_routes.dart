abstract final class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';

  // Home actions
  static const String pagar = '/pagar';
  static const String receber = '/receber';
  static const String enviar = '/enviar';
  static const String carteira = '/carteira';
  static const String facturas = '/facturas';
  static const String historico = '/historico';

  // Admin
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminMerchants = '/admin/merchants';
  static const String adminMerchantDetail = '/admin/merchants/detail';
  static const String adminApiKeys = '/admin/keys';
  static const String adminLimits = '/admin/limits';
  static const String adminProviders = '/admin/providers';
  static const String adminApiCalls = '/admin/calls';
  static const String adminAudit = '/admin/audit';
  static const String adminTeam = '/admin/team';
}
