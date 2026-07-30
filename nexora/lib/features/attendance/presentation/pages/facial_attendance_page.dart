import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../../../core/services/device_id_provider.dart';
import '../../data/native/mediapipe_face_detector.dart';

enum _Stage { idle, starting, detecting, verifying, result }

class FacialAttendancePage extends StatefulWidget {
  const FacialAttendancePage({super.key});

  @override
  State<FacialAttendancePage> createState() => _FacialAttendancePageState();
}

class _FacialAttendancePageState extends State<FacialAttendancePage>
    with WidgetsBindingObserver {
  static const _minScore = 0.6;
  static const _minFaceRatio = 0.15;
  static const _maxFaceRatio = 0.55;
  static const _centerTolerance = 0.20;
  static const _consecutiveGoodFramesToCapture = 15;

  CameraController? _controller;
  CameraDescription? _frontCamera;
  final _nativeDetector = MediaPipeFaceDetector();
  StreamSubscription<NativeFaceResult?>? _resultsSub;

  _Stage _stage = _Stage.idle;
  String _guidance = '';
  Rect? _faceBox;
  Size? _imageSize;
  bool _wellFramed = false;
  int _consecutiveGoodFrames = 0;
  bool _captureTriggered = false;
  bool _busy = false;

  File? _capturedFile;
  bool? _resultMatch;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _resultsSub?.cancel();
    _nativeDetector.close();
    super.dispose();
  }

  Future<void> _beginCapture() async {
    setState(() {
      _stage = _Stage.starting;
      _guidance = 'A iniciar câmara...';
      _consecutiveGoodFrames = 0;
      _captureTriggered = false;
      _capturedFile = null;
      _resultMatch = null;
      _resultMessage = null;
    });

    try {
      final cameras = await availableCameras();
      _frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;

      await _nativeDetector.init();
      _resultsSub?.cancel();
      _resultsSub = _nativeDetector.results.listen(_handleFaceResult);

      setState(() {
        _stage = _Stage.detecting;
        _guidance = 'Nenhum rosto detectado — posiciona-te em frente à câmara';
      });

      await controller.startImageStream(_analyzeFrame);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _stage = _Stage.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cameraErrorMessage(e))),
      );
    }
  }

  String _cameraErrorMessage(CameraException e) {
    if (e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt') {
      return 'Permissão de câmara necessária para captura facial.';
    }
    return 'Erro ao iniciar a câmara: ${e.description ?? e.code}';
  }

  Future<void> _stopCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    } catch (_) {
      // Já pode ter sido libertada — nada a fazer.
    }
  }

  void _analyzeFrame(CameraImage image) {
    if (_captureTriggered || _busy) return;
    final camera = _frontCamera;
    final controller = _controller;
    if (camera == null || controller == null) return;
    if (image.planes.isEmpty) return;

    _busy = true;
    final rotationDegrees = _computeRotationDegrees(camera, controller);
    _nativeDetector
        .detect(
          bytes: image.planes.first.bytes,
          width: image.width,
          height: image.height,
          rotationDegrees: rotationDegrees,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        )
        .catchError((_) {})
        .whenComplete(() => _busy = false);
  }

  void _handleFaceResult(NativeFaceResult? result) {
    if (_captureTriggered || !mounted) return;

    final wellFramed = result != null && _isWellFramed(result);
    _consecutiveGoodFrames = wellFramed ? _consecutiveGoodFrames + 1 : 0;

    setState(() {
      _faceBox = result?.boundingBox;
      _imageSize = result != null
          ? Size(result.imageWidth.toDouble(), result.imageHeight.toDouble())
          : null;
      _wellFramed = wellFramed;
      _guidance = _guidanceMessage(result, wellFramed);
    });

    if (_consecutiveGoodFrames >= _consecutiveGoodFramesToCapture) {
      _captureTriggered = true;
      _capture();
    }
  }

  bool _isWellFramed(NativeFaceResult result) {
    if (result.score < _minScore) return false;

    final imageArea = (result.imageWidth * result.imageHeight).toDouble();
    if (imageArea <= 0) return false;

    final box = result.boundingBox;
    final faceRatio = (box.width * box.height) / imageArea;
    if (faceRatio < _minFaceRatio || faceRatio > _maxFaceRatio) return false;

    final centerX = box.center.dx / result.imageWidth;
    final centerY = box.center.dy / result.imageHeight;
    final offCenterX = (centerX - 0.5).abs();
    final offCenterY = (centerY - 0.5).abs();
    return offCenterX <= _centerTolerance && offCenterY <= _centerTolerance;
  }

  String _guidanceMessage(NativeFaceResult? result, bool wellFramed) {
    if (result == null) {
      return 'Nenhum rosto detectado — posiciona-te em frente à câmara';
    }
    if (wellFramed) return 'Mantém-te parado...';

    final imageArea = (result.imageWidth * result.imageHeight).toDouble();
    final box = result.boundingBox;
    final faceRatio = imageArea > 0 ? (box.width * box.height) / imageArea : 0.0;
    if (faceRatio < _minFaceRatio) return 'Aproxima-te um pouco';
    if (faceRatio > _maxFaceRatio) return 'Afasta-te um pouco';
    return 'Centra o rosto no ecrã';
  }

  int _computeRotationDegrees(CameraDescription camera, CameraController controller) {
    final sensorOrientation = camera.sensorOrientation;
    var rotationCompensation =
        _orientationDegrees[controller.value.deviceOrientation] ?? 0;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    return rotationCompensation;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      _stage = _Stage.verifying;
      _guidance = '';
    });

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await _resultsSub?.cancel();
      _resultsSub = null;
      await _nativeDetector.close();

      final file = await controller.takePicture();
      _capturedFile = File(file.path);
      await controller.dispose();
      _controller = null;

      final bytes = await _capturedFile!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final deviceId = await sl<DeviceIdProvider>().getOrCreate();

      final response = await sl<AttendanceRemoteDataSource>().verifyFacial(
        deviceId: deviceId,
        imageBase64: base64Image,
      );

      if (!mounted) return;
      setState(() {
        _stage = _Stage.result;
        _resultMatch = response.match;
        _resultMessage = response.match
            ? 'Rosto reconhecido com sucesso.'
            : 'Rosto não reconhecido.${response.reason != null ? ' ${response.reason}' : ''}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.result;
        _resultMatch = false;
        _resultMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificação Facial')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_stage) {
      case _Stage.idle:
        return _IdleView(onStart: _beginCapture);
      case _Stage.starting:
        return const Center(child: CircularProgressIndicator());
      case _Stage.detecting:
        return _DetectingView(
          controller: _controller!,
          faceBox: _faceBox,
          imageSize: _imageSize,
          wellFramed: _wellFramed,
          guidance: _guidance,
        );
      case _Stage.verifying:
        return _VerifyingView(capturedFile: _capturedFile);
      case _Stage.result:
        return _ResultView(
          capturedFile: _capturedFile,
          match: _resultMatch ?? false,
          message: _resultMessage ?? '',
          onRetry: _beginCapture,
          onDone: () => Navigator.of(context).pop(_resultMatch == true),
        );
    }
  }
}

const _orientationDegrees = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

class _IdleView extends StatelessWidget {
  final VoidCallback onStart;

  const _IdleView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.face_outlined, size: 72, color: AppColors.brandAccent),
          const SizedBox(height: 16),
          const Text(
            'Posiciona o rosto em frente à câmara para registar a presença.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onStart, child: const Text('Iniciar')),
        ],
      ),
    );
  }
}

class _DetectingView extends StatelessWidget {
  final CameraController controller;
  final Rect? faceBox;
  final Size? imageSize;
  final bool wellFramed;
  final String guidance;

  const _DetectingView({
    required this.controller,
    required this.faceBox,
    required this.imageSize,
    required this.wellFramed,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(controller),
                        if (faceBox != null && imageSize != null)
                          CustomPaint(
                            painter: _FaceBoxPainter(
                              box: faceBox!,
                              imageSize: imageSize!,
                              color: wellFramed ? Colors.green : Colors.amber,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          guidance,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FaceBoxPainter extends CustomPainter {
  final Rect box;
  final Size imageSize;
  final Color color;

  _FaceBoxPainter({required this.box, required this.imageSize, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final rect = Rect.fromLTRB(
      box.left * scaleX,
      box.top * scaleY,
      box.right * scaleX,
      box.bottom * scaleY,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceBoxPainter oldDelegate) {
    return oldDelegate.box != box || oldDelegate.color != color;
  }
}

class _VerifyingView extends StatelessWidget {
  final File? capturedFile;

  const _VerifyingView({required this.capturedFile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (capturedFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(capturedFile!, width: 220, height: 220, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const Text('A verificar...', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final File? capturedFile;
  final bool match;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  const _ResultView({
    required this.capturedFile,
    required this.match,
    required this.message,
    required this.onRetry,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (capturedFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(capturedFile!, width: 220, height: 220, fit: BoxFit.cover),
            ),
          const SizedBox(height: 20),
          Icon(
            match ? Icons.check_circle_outline : Icons.error_outline,
            size: 48,
            color: match ? AppColors.green : AppColors.red,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          if (match)
            FilledButton(onPressed: onDone, child: const Text('Concluído'))
          else
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
