import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_method.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class QrAttendancePage extends StatelessWidget {
  const QrAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>(),
      child: const _QrAttendanceView(),
    );
  }
}

class _QrAttendanceView extends StatefulWidget {
  const _QrAttendanceView();

  @override
  State<_QrAttendanceView> createState() => _QrAttendanceViewState();
}

class _QrAttendanceViewState extends State<_QrAttendanceView> {
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture, BuildContext context) {
    if (_scanned) return;

    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.displayValue ?? barcode?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _scanned = true);

    context.read<AttendanceBloc>().add(
          RegisterAttendance(
            method: AttendanceMethod.qrCode,
            payload: {'qr_code': code},
          ),
        );
  }

  void _reset() {
    setState(() => _scanned = false);
    context.read<AttendanceBloc>().add(const ResetAttendanceResult());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registo por QR Code')),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AttendanceLoading) {
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
                      onPressed: _reset,
                      child: const Text('Escanear outro'),
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
                  'Aponta a câmara para o QR code para marcar o ponto. O tipo de evento será determinado automaticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      onDetect: (capture) => _onDetect(capture, context),
                      overlay: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.brandAccent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
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
