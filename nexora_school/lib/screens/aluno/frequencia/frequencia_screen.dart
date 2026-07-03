import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../features/student_portal/domain/entities/student_presencas_data.dart';
import '../../../features/student_portal/presentation/cubit/student_presencas_cubit.dart';
import '../../../features/student_portal/presentation/cubit/student_presencas_state.dart';
import 'faltas_screen.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _red = Color(0xFFEF4444);
const _orange = Color(0xFFF59E0B);

class FrequenciaScreen extends StatelessWidget {
  const FrequenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentPresencasCubit>()..load(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: _navy,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Frequência',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<StudentPresencasCubit, StudentPresencasState>(
          builder: (context, state) {
            return switch (state) {
              StudentPresencasLoading() => const Center(
                child: CircularProgressIndicator(color: _green),
              ),
              StudentPresencasError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erro ao carregar: $message',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              StudentPresencasLoaded(:final data) => _buildContent(
                context,
                data,
              ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StudentPresencasData data) {
    final total = data.records.length;
    final faltas = data.records
        .where((r) => (r['estado'] ?? '').toString() == 'ausente')
        .length;
    final presencas = total - faltas;
    final pct = total == 0 ? 0 : ((presencas / total) * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(total, faltas, presencas, pct),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaltasScreen()),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver registo de faltas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _green),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Registos de presença',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 14),
          ...data.records.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRegistoCard(r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int total, int faltas, int presencas, int pct) {
    final color = pct >= 75 ? _green : (pct >= 60 ? _orange : _red);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRESENÇA GLOBAL',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$presencas presenças de $total registos',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statPill(
                '$faltas faltas',
                Icons.cancel_outlined,
                Colors.white.withValues(alpha: 0.2),
                Colors.white,
              ),
              const SizedBox(height: 8),
              _statPill(
                pct >= 75 ? 'Regular' : 'Em risco',
                pct >= 75
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                Colors.white.withValues(alpha: 0.2),
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistoCard(dynamic r) {
    final estado = (r['estado'] ?? '').toString();
    final data = (r['attendance_date'] ?? '').toString();
    final ausente = estado == 'ausente';
    final color = ausente ? _red : _green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ausente ? Icons.cancel_outlined : Icons.check_circle_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.isNotEmpty ? _formatDate(data) : '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ausente ? 'Ausente' : 'Presente',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
