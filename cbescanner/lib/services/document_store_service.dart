import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/scanned_document.dart';
import 'native_document_scanner.dart';

class DocumentStoreSnapshot {
  final List<ScannedDocument> documents;
  final int totalBytes;

  const DocumentStoreSnapshot({
    required this.documents,
    required this.totalBytes,
  });

  int get count => documents.length;
}

class DocumentStoreService {
  static const _folderName = 'documentos_digitalizados';
  static const highVolumePageLimit = 300;

  Future<Directory> _documentsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<ScannedDocument>> listDocuments() async {
    final snapshot = await loadSnapshot();
    return snapshot.documents;
  }

  Future<DocumentStoreSnapshot> loadSnapshot() async {
    final dir = await _documentsDir();
    final documents = <ScannedDocument>[];
    var totalBytes = 0;

    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.pdf')) {
        continue;
      }
      final document = await ScannedDocument.fromFile(entity);
      documents.add(document);
      totalBytes += document.sizeBytes;
    }

    documents.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return DocumentStoreSnapshot(documents: documents, totalBytes: totalBytes);
  }

  /// Abre o scanner nativo (câmara) e deixa o utilizador digitalizar uma ou
  /// várias páginas, devolvendo o PDF resultante ainda por guardar.
  ///
  /// Retorna `null` se o utilizador cancelar a digitalização.
  Future<File?> scanDocument() async {
    final scannedPath = await NativeDocumentScanner.scanDocument(
      pageLimit: highVolumePageLimit,
    );
    if (scannedPath == null) return null;
    return File(scannedPath);
  }

  /// Nome sugerido por defeito para um novo documento digitalizado.
  String suggestedName() => _generateFileName();

  /// Move o PDF digitalizado (temporário) para a pasta de documentos,
  /// guardando-o com o nome escolhido pelo utilizador.
  Future<ScannedDocument> saveDocument(File scannedFile, String name) async {
    final dir = await _documentsDir();
    final sanitized = _sanitizeName(name, fallback: _generateFileName());
    final destination = await _uniqueDestination(dir, sanitized);
    await _moveFile(scannedFile, destination);
    return ScannedDocument.fromFile(destination);
  }

  Future<ScannedDocument> rename(
    ScannedDocument document,
    String newName,
  ) async {
    final dir = await _documentsDir();
    final sanitized = _sanitizeName(newName, fallback: document.name);
    final destination = await _uniqueDestination(
      dir,
      sanitized,
      currentPath: document.path,
    );
    final renamed = await document.file.rename(destination.path);
    return ScannedDocument.fromFile(renamed);
  }

  Future<void> delete(ScannedDocument document) async {
    if (await document.file.exists()) {
      await document.file.delete();
    }
  }

  Future<void> _moveFile(File source, File destination) async {
    try {
      await source.rename(destination.path);
    } on FileSystemException {
      await source.copy(destination.path);
      if (await source.exists()) {
        await source.delete();
      }
    }
  }

  Future<File> _uniqueDestination(
    Directory dir,
    String baseName, {
    String? currentPath,
  }) async {
    var candidate = File('${dir.path}/$baseName.pdf');
    if (_samePath(candidate.path, currentPath) || !await candidate.exists()) {
      return candidate;
    }

    for (var index = 2;; index++) {
      candidate = File('${dir.path}/$baseName-$index.pdf');
      if (_samePath(candidate.path, currentPath) || !await candidate.exists()) {
        return candidate;
      }
    }
  }

  bool _samePath(String path, String? otherPath) {
    if (otherPath == null) return false;
    return path.toLowerCase() == otherPath.toLowerCase();
  }

  String _sanitizeName(String value, {required String fallback}) {
    final trimmed = value.trim().isEmpty ? fallback : value.trim();
    final sanitized = trimmed
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^\.+|\.+$'), '')
        .trim();
    return sanitized.isEmpty ? fallback : sanitized;
  }

  String _generateFileName() {
    final now = DateTime.now();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return 'Documento_${now.year}${twoDigits(now.month)}${twoDigits(now.day)}'
        '_${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}';
  }
}
