import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_method.dart';
import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/attendance_status.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>()..add(const LoadTodayAttendanceStatus()),
      child: const _AttendanceHistoryView(),
    );
  }
}

class _AttendanceHistoryView extends StatelessWidget {
  const _AttendanceHistoryView();

  Future<void> _refresh(BuildContext context) async {
    context.read<AttendanceBloc>().add(const LoadTodayAttendanceStatus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assiduidade')),
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

          final records = state is AttendanceTodayStatusLoaded
              ? state.records
              : state is AttendanceHistoryLoaded
                  ? state.records
                  : <AttendanceRecordEntity>[];

          final todayRecords = records
              .where(
                (r) =>
                    r.recordedAt.year == DateTime.now().year &&
                    r.recordedAt.month == DateTime.now().month &&
                    r.recordedAt.day == DateTime.now().day,
              )
              .toList();

          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TodayStatusCard(records: todayRecords),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Registos recentes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${records.length} registo(s)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (records.isEmpty)
                  const _EmptyState(
                    message: 'Sem registos de assiduidade para o período seleccionado.',
                  )
                else
                  ..._buildGroupedRecords(records),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedRecords(List<AttendanceRecordEntity> records) {
    final sorted = List<AttendanceRecordEntity>.from(records)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final groups = <DateTime, List<AttendanceRecordEntity>>{};
    for (final record in sorted) {
      final date = DateTime(
        record.recordedAt.year,
        record.recordedAt.month,
        record.recordedAt.day,
      );
      groups.putIfAbsent(date, () => []).add(record);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            _formatGroupDate(entry.key),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
      widgets.addAll(
        entry.value.map((record) => _RecordTile(record: record)),
      );
    }
    return widgets;
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Hoje';
    if (date == yesterday) return 'Ontem';
    return DateFormat('EEEE, d \'de\' MMMM', 'pt_PT').format(date);
  }
}

class _TodayStatusCard extends StatelessWidget {
  final List<AttendanceRecordEntity> records;

  const _TodayStatusCard({required this.records});

  AttendanceRecordEntity? get _firstIn => records
      .where((r) => r.type == AttendanceType.entrada)
      .reduceOrNull((a, b) => a.recordedAt.isBefore(b.recordedAt) ? a : b);

  AttendanceRecordEntity? get _lastOut => records
      .where((r) => r.type == AttendanceType.saida)
      .reduceOrNull((a, b) => a.recordedAt.isAfter(b.recordedAt) ? a : b);

  String? get _workedHours {
    final firstIn = _firstIn;
    final lastOut = _lastOut;
    if (firstIn == null) return null;

    final end = lastOut?.recordedAt ?? DateTime.now();
    final diff = end.difference(firstIn.recordedAt);
    final hours = diff.inMinutes ~/ 60;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado de hoje',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatusItem(
                    icon: Icons.login,
                    label: 'Entrada',
                    value: _firstIn != null
                        ? _formatTime(_firstIn!.recordedAt)
                        : '—',
                    color: AppColors.green,
                  ),
                ),
                Expanded(
                  child: _StatusItem(
                    icon: Icons.logout,
                    label: 'Saída',
                    value: _lastOut != null
                        ? _formatTime(_lastOut!.recordedAt)
                        : '—',
                    color: AppColors.red,
                  ),
                ),
                Expanded(
                  child: _StatusItem(
                    icon: Icons.access_time,
                    label: 'Horas',
                    value: _workedHours ?? '—',
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecordEntity record;

  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isEntrada = record.type == AttendanceType.entrada;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEntrada ? AppColors.green : AppColors.red,
          child: Icon(
            isEntrada ? Icons.login : Icons.logout,
            color: Colors.white,
          ),
        ),
        title: Text(
          isEntrada ? 'Entrada' : 'Saída',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_methodLabel(record.method)),
        trailing: Text(
          _formatTime(record.recordedAt),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  String _methodLabel(AttendanceMethod method) {
    switch (method) {
      case AttendanceMethod.manual:
        return 'Manual';
      case AttendanceMethod.qrCode:
        return 'QR Code';
      case AttendanceMethod.facial:
        return 'Facial';
      case AttendanceMethod.selfieGps:
        return 'Selfie + GPS';
      case AttendanceMethod.pin:
        return 'PIN';
      case AttendanceMethod.nfc:
        return 'NFC';
      case AttendanceMethod.fingerprint:
        return 'Biometria';
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.access_time_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

extension _ReduceOrNull<T> on Iterable<T> {
  T? reduceOrNull(T Function(T a, T b) combine) {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    var value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }
}
