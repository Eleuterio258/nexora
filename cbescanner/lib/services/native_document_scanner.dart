import 'package:flutter/services.dart';

/// Ponte para o scanner de documentos nativo (Android: ML Kit
/// GmsDocumentScanning, chamado diretamente a partir do MainActivity.kt).
class NativeDocumentScanner {
  static const _channel = MethodChannel('cbescanner/document_scanner');

  /// Abre o scanner nativo e devolve o caminho do PDF gerado, ou `null` se o
  /// utilizador cancelar a digitalização.
  static Future<String?> scanDocument({int pageLimit = 300}) {
    return _channel.invokeMethod<String>('scanDocument', {
      'pageLimit': pageLimit,
    });
  }
}
