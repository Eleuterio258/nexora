import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/student_portal/domain/entities/student_boletim_data.dart';
import '../../../../features/student_portal/presentation/cubit/student_boletim_cubit.dart';
import '../../../../features/student_portal/presentation/cubit/student_boletim_state.dart';

class BoletimTab extends StatefulWidget {
  const BoletimTab({super.key});

  @override
  State<BoletimTab> createState() => _BoletimTabState();
}

class _BoletimTabState extends State<BoletimTab> {
  int _termIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cs = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00B87A),
      brightness: Brightness.light,
    );
    final tt = Theme.of(context).textTheme;

    return Theme(
      data: ThemeData(colorScheme: cs, useMaterial3: true),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(cs, tt),
              Expanded(
                child: BlocBuilder<StudentBoletimCubit, StudentBoletimState>(
                  builder: (context, state) {
                    return switch (state) {
                      StudentBoletimLoading() => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      StudentBoletimError(:final message) => Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Erro ao carregar boletim: $message', textAlign: TextAlign.center),
                      )),
                      StudentBoletimLoaded(:final data) => _buildContent(data, cs, tt),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boletim',
                  style: tt.headlineMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Notas e desempenho escolar',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StudentBoletimData data, ColorScheme cs, TextTheme tt) {
    final termos = data.terms.map((t) => (t['nome'] ?? 'Período').toString()).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStudentStatsCard(data.media, cs, tt),
          const SizedBox(height: 20),
          if (termos.isNotEmpty) _buildTermChips(termos, cs),
          const SizedBox(height: 16),
          Text(
            'Disciplinas',
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...data.grades.map((g) => _buildDisciplinaItem(g, cs, tt)),
          if (data.grades.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('Ainda não há notas lançadas para este período.')),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentStatsCard(
    double media,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final mediaStr = media.toStringAsFixed(1).replaceAll('.', ',');
    final aprovado = media >= 10.0;
    const fg = Colors.white;

    return Card(
      elevation: 0,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: fg.withValues(alpha: 0.20),
                  child: const Icon(Icons.person_rounded, color: fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Média Geral',
                          style: tt.titleSmall?.copyWith(
                              color: fg, fontWeight: FontWeight.bold)),
                      Text('/ 20 valores',
                          style: tt.bodySmall?.copyWith(
                              color: fg.withValues(alpha: 0.75))),
                    ],
                  ),
                ),
                Text(mediaStr,
                    style: tt.displayMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.bold,
                        height: 1.1)),
              ],
            ),
            Divider(color: fg.withValues(alpha: 0.20), height: 24),
            Row(
              children: [
                Icon(
                  aprovado
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: aprovado ? AppColors.warning : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  aprovado ? 'Aprovado' : 'Em Risco',
                  style: tt.labelLarge?.copyWith(
                      color: aprovado ? AppColors.warning : AppColors.error,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermChips(List<String> termos, ColorScheme cs) {
    return Wrap(
      spacing: 8,
      children: List.generate(termos.length, (i) {
        return FilterChip(
          label: Text(termos[i]),
          selected: _termIndex == i,
          showCheckmark: false,
          onSelected: (_) {
            setState(() => _termIndex = i);
            final termId = i < (context.read<StudentBoletimCubit>().state as StudentBoletimLoaded).data.terms.length
                ? ((context.read<StudentBoletimCubit>().state as StudentBoletimLoaded).data.terms[i]['id'] as int? ?? 0)
                : 0;
            context.read<StudentBoletimCubit>().load(termId: termId > 0 ? termId : null);
          },
        );
      }),
    );
  }

  Widget _buildDisciplinaItem(dynamic grade, ColorScheme cs, TextTheme tt) {
    final nome = (grade['nome'] ?? grade['subject_name'] ?? 'Disciplina').toString();
    final media = _toDouble(grade['media']);
    final avaliacoes = (grade['avaliacoes'] ?? 0).toString();
    final notaStr = media == media.truncateToDouble()
        ? media.toInt().toString()
        : media.toStringAsFixed(1).replaceAll('.', ',');
    final ok = media >= 10.0;
    final notaColor = ok ? cs.primary : cs.error;
    final color = _subjectColor(nome);

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(Icons.menu_book_outlined, color: color, size: 24),
        title: Text(
          nome,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$avaliacoes avaliações',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Text(
          notaStr,
          style: tt.titleMedium?.copyWith(
            color: notaColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static Color _subjectColor(String nome) {
    final lower = nome.toLowerCase();
    if (lower.contains('matem')) return const Color(0xFF10B981);
    if (lower.contains('fisica') || lower.contains('física')) return const Color(0xFFF59E0B);
    if (lower.contains('quimica') || lower.contains('química')) return const Color(0xFFEC4899);
    if (lower.contains('biologia')) return const Color(0xFF06B6D4);
    if (lower.contains('geografia')) return const Color(0xFF6366F1);
    if (lower.contains('historia') || lower.contains('história')) return const Color(0xFFEF4444);
    if (lower.contains('ingles') || lower.contains('inglês')) return const Color(0xFF8B5CF6);
    if (lower.contains('portug')) return const Color(0xFF3B82F6);
    if (lower.contains('desenho')) return const Color(0xFF14B8A6);
    if (lower.contains('informatica') || lower.contains('informática')) return const Color(0xFF06B6D4);
    return const Color(0xFF64748B);
  }
}
