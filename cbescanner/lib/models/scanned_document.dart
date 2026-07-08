import 'dart:io';

class ScannedDocument {
  final File file;
  final DateTime modifiedAt;
  final int sizeBytes;

  ScannedDocument({
    required this.file,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  String get name {
    final fileName = file.uri.pathSegments.last;
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }

  String get path => file.path;

  static Future<ScannedDocument> fromFile(File file) async {
    final stat = await file.stat();
    return ScannedDocument(
      file: file,
      modifiedAt: stat.modified,
      sizeBytes: stat.size,
    );
  }
}
