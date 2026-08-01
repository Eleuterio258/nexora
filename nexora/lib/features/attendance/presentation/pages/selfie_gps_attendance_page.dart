import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_method.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class SelfieGpsAttendancePage extends StatelessWidget {
  const SelfieGpsAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>(),
      child: const _SelfieGpsAttendanceView(),
    );
  }
}

class _SelfieGpsAttendanceView extends StatefulWidget {
  const _SelfieGpsAttendanceView();

  @override
  State<_SelfieGpsAttendanceView> createState() =>
      _SelfieGpsAttendanceViewState();
}

class _SelfieGpsAttendanceViewState extends State<_SelfieGpsAttendanceView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _frontCamera;
  bool _isCapturing = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_controller != null) return;

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
      );
      _controller = controller;
      await controller.initialize();
      if (mounted) setState(() {});
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_cameraErrorMessage(e))),
        );
      }
    }
  }

  void _disposeCamera() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = 'Serviço de localização desativado.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationError = 'Permissão de localização negada.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationError = 'Permissão de localização negada permanentemente.');
        return;
      }
    } on PlatformException catch (e) {
      setState(() => _locationError = 'Erro ao aceder à localização: ${e.message}');
    }
  }

  String _cameraErrorMessage(CameraException e) {
    if (e.code == 'CameraAccessDenied' ||
        e.code == 'CameraAccessDeniedWithoutPrompt') {
      return 'Permissão de câmara necessária.';
    }
    return 'Erro ao iniciar a câmara: ${e.description ?? e.code}';
  }

  Future<void> _captureAndSubmit(BuildContext context) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _isCapturing = true);

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      } catch (_) {
        // Continua sem localização se falhar
      }

      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!context.mounted) return;

      context.read<AttendanceBloc>().add(
            RegisterAttendance(
              method: AttendanceMethod.selfieGps,
              geoLat: position?.latitude,
              geoLng: position?.longitude,
              payload: {'image_base64': base64Image},
            ),
          );
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_cameraErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selfie + GPS')),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AttendanceLoading || _isCapturing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AttendanceRegistered) {
            final record = state.record;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      record.status == 'ok'
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 64,
                      color: record.status == 'ok'
                          ? AppColors.green
                          : AppColors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      record.status == 'ok'
                          ? 'Presença registada'
                          : (record.message ?? 'Registo não confirmado'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        context
                            .read<AttendanceBloc>()
                            .add(const ResetAttendanceResult());
                      },
                      child: const Text('Nova foto'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tira uma selfie. A localização GPS será anexada ao registo e o tipo de evento será determinado automaticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _controller?.value.isInitialized == true
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(math.pi),
                            child: AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: CameraPreview(_controller!),
                            ),
                          )
                        : Container(
                            color: AppColors.border,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                  ),
                ),
              ),
              if (_locationError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _locationError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.red, fontSize: 13),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _controller?.value.isInitialized == true
                        ? () => _captureAndSubmit(context)
                        : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capturar e marcar ponto'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
