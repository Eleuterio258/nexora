import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../../cubit/student_eventos_cubit.dart';
import '../../../cubit/student_eventos_state.dart';
import '../../../../domain/entities/student_evento.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

const _meses = ['JAN','FEV','MAR','ABR','MAI','JUN','JUL','AGO','SET','OUT','NOV','DEZ'];

class CalendarioScreen extends StatelessWidget {
  const CalendarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentEventosCubit>()..load(),
      child: const _CalendarioView(),
    );
  }
}

class _CalendarioView extends StatelessWidget {
  const _CalendarioView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calendário',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
            Text('Eventos académicos',
                style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: BlocBuilder<StudentEventosCubit, StudentEventosState>(
        builder: (context, state) {
          if (state is StudentEventosLoading || state is StudentEventosInitial) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is StudentEventosError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFF8E8E93), size: 40),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Color(0xFF8E8E93))),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<StudentEventosCubit>().load(),
                    child: const Text('Tentar novamente',
                        style: TextStyle(color: _green)),
                  ),
                ],
              ),
            );
          }
          if (state is StudentEventosLoaded) {
            final eventos = state.eventos;
            if (eventos.isEmpty) {
              return const Center(
                child: Text('Sem eventos programados',
                    style: TextStyle(color: Color(0xFF8E8E93))),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: eventos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _EventoCard(item: eventos[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.item});
  final StudentEvento item;

  static Color _parseColor(String? cor) {
    if (cor != null && cor.length == 7 && cor.startsWith('#')) {
      final hex = int.tryParse('0xFF${cor.substring(1)}');
      if (hex != null) return Color(hex);
    }
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(item.cor);
    final dt = DateTime.tryParse(item.dataInicio);
    final dia = dt != null ? dt.day.toString().padLeft(2, '0') : '--';
    final mes = dt != null ? _meses[dt.month - 1] : '--';
    final hora = item.diaInteiro
        ? '—'
        : (dt != null
            ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
            : '—');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mes,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                Text(dia,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: _navy, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
                if (item.tipo != null && item.tipo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(item.tipo!,
                        style: TextStyle(fontSize: 11, color: color)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(hora,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
