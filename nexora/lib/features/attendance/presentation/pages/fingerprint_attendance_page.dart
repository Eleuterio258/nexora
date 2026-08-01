import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_method.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class FingerprintAttendancePage extends StatelessWidget {
  const FingerprintAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>(),
      child: const _FingerprintAttendanceView(),
    );
  }
}

class _FingerprintAttendanceView extends StatefulWidget {
  const _FingerprintAttendanceView();

  @override
  State<_FingerprintAttendanceView> createState() =>
      _FingerprintAttendanceViewState();
}

class _FingerprintAttendanceViewState
    extends State<_FingerprintAttendanceView> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck;
          _availableBiometrics = available;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _canCheckBiometrics = false);
    }
  }

  Future<void> _authenticate(BuildContext context) async {
    if (_canCheckBiometrics != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometria não disponível neste dispositivo.')),
      );
      return;
    }

    final hasFingerprint = _availableBiometrics?.contains(BiometricType.fingerprint) == true ||
        _availableBiometrics?.contains(BiometricType.strong) == true;
    final hasFace = _availableBiometrics?.contains(BiometricType.face) == true ||
        _availableBiometrics?.contains(BiometricType.weak) == true;

    if (!hasFingerprint && !hasFace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma biometria configurada no dispositivo.')),
      );
      return;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirma a tua identidade para marcar o ponto.',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (!context.mounted) return;

      if (authenticated) {
        context.read<AttendanceBloc>().add(
              const RegisterAttendance(
                method: AttendanceMethod.fingerprint,
              ),
            );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na autenticação: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impressão Digital / Biometria')),
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
                      onPressed: () {
                        context
                            .read<AttendanceBloc>()
                            .add(const ResetAttendanceResult());
                      },
                      child: const Text('Novo registo'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: AppColors.brandAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Utiliza a biometria do dispositivo para marcar o ponto. O tipo de evento será determinado automaticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),
                if (_canCheckBiometrics == false)
                  const Text(
                    'Biometria não disponível neste dispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.red),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _authenticate(context),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Autenticar e marcar ponto'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
