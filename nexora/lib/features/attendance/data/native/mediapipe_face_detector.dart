import 'package:flutter/services.dart';

class NativeFaceResult {
  final Rect boundingBox;
  final double score;
  final int imageWidth;
  final int imageHeight;

  const NativeFaceResult({
    required this.boundingBox,
    required this.score,
    required this.imageWidth,
    required this.imageHeight,
  });
}

/// Cliente do detector facial nativo (MediaPipe FaceDetector / BlazeFace
/// short-range) — ver `MediaPipeFaceDetectorHandler.kt`. Substitui o ML Kit
/// porque não há pacote Flutter oficial para MediaPipe Tasks Vision.
class MediaPipeFaceDetector {
  static const _methodChannel = MethodChannel('nexora/face_detector');
  static const _eventChannel = EventChannel('nexora/face_detector/results');

  Future<void> init() => _methodChannel.invokeMethod('init');

  Stream<NativeFaceResult?> get results {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final map = Map<Object?, Object?>.from(event as Map);
      if (map['hasFace'] != true) return null;

      return NativeFaceResult(
        boundingBox: Rect.fromLTRB(
          (map['left'] as num).toDouble(),
          (map['top'] as num).toDouble(),
          (map['right'] as num).toDouble(),
          (map['bottom'] as num).toDouble(),
        ),
        score: (map['score'] as num).toDouble(),
        imageWidth: (map['imageWidth'] as num).toInt(),
        imageHeight: (map['imageHeight'] as num).toInt(),
      );
    });
  }

  Future<void> detect({
    required Uint8List bytes,
    required int width,
    required int height,
    required int rotationDegrees,
    required int timestampMs,
  }) {
    return _methodChannel.invokeMethod('detect', {
      'bytes': bytes,
      'width': width,
      'height': height,
      'rotationDegrees': rotationDegrees,
      'timestampMs': timestampMs,
    });
  }

  Future<void> close() => _methodChannel.invokeMethod('close');
}
