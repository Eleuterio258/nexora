class AppConfig {
  static const String erpBaseUrl = String.fromEnvironment(
    'ERP_BASE_URL',
    defaultValue: 'https://api.nexora.e258tech.tech',
  );

  static const String oauthClientId = 'android-app';
}
