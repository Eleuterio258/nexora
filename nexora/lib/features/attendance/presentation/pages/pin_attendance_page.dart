import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_method.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class PinAttendancePage extends StatelessWidget {
  const PinAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>(),
      child: const _PinAttendanceView(),
    );
  }
}

class _PinAttendanceView extends StatefulWidget {
  const _PinAttendanceView();

  @override
  State<_PinAttendanceView> createState() => _PinAttendanceViewState();
}

class _PinAttendanceViewState extends State<_PinAttendanceView> {
  String _pin = '';

  void _onDigit(String digit) {
    if (_pin.length < 6) {
      setState(() => _pin += digit);
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _onSubmit(BuildContext context) {
    if (_pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O PIN deve ter pelo menos 4 dígitos.')),
      );
      return;
    }

    context.read<AttendanceBloc>().add(
          RegisterAttendance(
            method: AttendanceMethod.pin,
            payload: {'pin': _pin},
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registo por PIN')),
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
                        setState(() => _pin = '');
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Insere o teu PIN para marcar o ponto. O sistema determina automaticamente se é entrada ou saída.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                _PinDots(pin: _pin),
                const SizedBox(height: 24),
                Expanded(
                    child: _PinPad(
                        onDigit: _onDigit, onBackspace: _onBackspace)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _pin.length >= 4 ? () => _onSubmit(context) : null,
                    child: const Text('Marcar ponto'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final String pin;

  const _PinDots({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < pin.length;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.brandAccent : AppColors.borderStrong,
          ),
        );
      }),
    );
  }
}

class _PinPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _PinPad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'backspace'],
        ])
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((label) {
                if (label == 'backspace') {
                  return _PinKey(
                    onTap: onBackspace,
                    child: const Icon(Icons.backspace_outlined),
                  );
                }
                if (label.isEmpty) {
                  return const SizedBox(width: 72);
                }
                return _PinKey(
                  label: label,
                  onTap: () => onDigit(label),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback onTap;

  const _PinKey({this.label, this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Center(
          child: child ??
              Text(
                label!,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
        ),
      ),
    );
  }
}
