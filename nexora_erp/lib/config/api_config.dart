import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiConfig {
  // Emulador Android não alcança "localhost" do host — usa o IP especial
  // 10.0.2.2. iOS/desktop/web usam localhost directamente. Usa
  // defaultTargetPlatform (não dart:io Platform) para não quebrar no web.
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
