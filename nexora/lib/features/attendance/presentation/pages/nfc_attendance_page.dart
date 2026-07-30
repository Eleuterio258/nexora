import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_method.dart';
import '../../domain/entities/attendance_status.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class NfcAttendancePage extends StatelessWidget {
  const NfcAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>(),
      child: const _NfcAttendanceView(),
    );
  }
}

class _NfcAttendanceView extends StatefulWidget {
  const _NfcAttendanceView();

  @override
  State<_NfcAttendanceView> createState() => _NfcAttendanceViewState();
}

class _NfcAttendanceViewState extends State<_NfcAttendanceView> {
  bool _isAvailable = false;
  bool _isReading = false;
  AttendanceType _selectedType = AttendanceType.entrada;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await NfcManager.instance.isAvailable();
    if (mounted) setState(() => _isAvailable = available);
  }

  Future<void> _startNfcSession(BuildContext context) async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC não disponível neste dispositivo.')),
      );
      return;
    }

    setState(() => _isReading = true);

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        String? tagId;
        final nfcA = tag.data['nfca'];
        final nfcB = tag.data['nfcb'];
        final nfcF = tag.data['nfcf'];
        final nfcV = tag.data['nfcv'];
        final isoDep = tag.data['isodep'];
        final mifare = tag.data['mifare'];
        final ndef = tag.data['ndef'];

        // Tenta obter um identificador único da tag
        tagId = _extractIdentifier(nfcA) ??
            _extractIdentifier(nfcB) ??
            _extractIdentifier(nfcF) ??
            _extractIdentifier(nfcV) ??
            _extractIdentifier(isoDep) ??
            _extractIdentifier(mifare);

        // Se não houver identificador, tenta ler NDEF
        if (tagId == null && ndef != null) {
          final cachedMessage = ndef['cachedMessage'];
          if (cachedMessage is Map) {
            final records = cachedMessage['records'] as List?;
            if (records != null && records.isNotEmpty) {
              final firstRecord = records.first as Map?;
              final payload = firstRecord?['payload'];
              if (payload != null) {
                tagId = utf8.decode(payload, allowMalformed: true);
              }
            }
          }
        }

        tagId ??= tag.data.toString();

        await NfcManager.instance.stopSession();

        if (!context.mounted) return;

        context.read<AttendanceBloc>().add(
              RegisterAttendance(
                method: AttendanceMethod.nfc,
                type: _selectedType,
                payload: {'nfc_tag_id': tagId},
              ),
            );

        if (mounted) setState(() => _isReading = false);
      },
      onError: (e) async {
        if (mounted) setState(() => _isReading = false);
      },
    );
  }

  String? _extractIdentifier(dynamic data) {
    if (data is! Map) return null;
    final identifier = data['identifier'];
    if (identifier == null) return null;
    if (identifier is List<int>) {
      return identifier.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
    }
    return identifier.toString();
  }

  @override
  void dispose() {
    if (_isReading) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registo por NFC')),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AttendanceLoading || _isReading) {
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
                      child: const Text('Nova leitura'),
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
                  Icons.nfc,
                  size: 80,
                  color: AppColors.brandAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aproxima o cartão ou dispositivo NFC do telemóvel para registar a presença.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                SegmentedButton<AttendanceType>(
                  segments: const [
                    ButtonSegment(
                      value: AttendanceType.entrada,
                      label: Text('Entrada'),
                      icon: Icon(Icons.login),
                    ),
                    ButtonSegment(
                      value: AttendanceType.saida,
                      label: Text('Saída'),
                      icon: Icon(Icons.logout),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (selected) {
                    setState(() => _selectedType = selected.first);
                  },
                ),
                const SizedBox(height: 32),
                if (!_isAvailable)
                  const Text(
                    'NFC não disponível neste dispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.red),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _startNfcSession(context),
                    icon: const Icon(Icons.nfc),
                    label: const Text('Iniciar leitura NFC'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
