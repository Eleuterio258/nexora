import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_method.dart';
import '../../domain/entities/attendance_status.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class ManualAttendancePage extends StatelessWidget {
  const ManualAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>(),
      child: const _ManualAttendanceView(),
    );
  }
}

class _ManualAttendanceView extends StatelessWidget {
  const _ManualAttendanceView();

  Future<void> _confirmAndRegister(
    BuildContext context,
    AttendanceType type,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar ${type == AttendanceType.entrada ? 'entrada' : 'saída'}'),
        content: Text(
          'Deseja registar a ${type == AttendanceType.entrada ? 'entrada' : 'saída'} manualmente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AttendanceBloc>().add(
            RegisterAttendance(
              method: AttendanceMethod.manual,
              type: type,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registo Manual')),
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
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Presença registada com sucesso',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${record.type == AttendanceType.entrada ? 'Entrada' : 'Saída'} às ${_formatTime(record.recordedAt)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context
                          .read<AttendanceBloc>()
                          .add(const ResetAttendanceResult()),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Escolhe o tipo de registo que pretendes efectuar.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),
                _ActionCard(
                  icon: Icons.login,
                  label: 'Registar Entrada',
                  color: AppColors.green,
                  onTap: () => _confirmAndRegister(context, AttendanceType.entrada),
                ),
                const SizedBox(height: 16),
                _ActionCard(
                  icon: Icons.logout,
                  label: 'Registar Saída',
                  color: AppColors.red,
                  onTap: () => _confirmAndRegister(context, AttendanceType.saida),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
