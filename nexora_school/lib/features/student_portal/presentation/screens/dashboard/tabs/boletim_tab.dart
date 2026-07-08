import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/constants/app_colors.dart';
import 'package:nexora_school/features/student_portal/domain/entities/student_boletim_data.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_boletim_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_boletim_state.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);
const _red = Color(0xFFEF4444);

class BoletimTab extends StatefulWidget {
  const BoletimTab({super.key});

  @override
  State<BoletimTab> createState() => _BoletimTabState();
}

class _BoletimTabState extends State<BoletimTab> {
  int _termIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: BlocBuilder<StudentBoletimCubit, StudentBoletimState>(
                builder: (context, state) => switch (state) {
                  StudentBoletimLoading() => const Center(
                      child: CircularProgressIndicator(color: _green)),
                  StudentBoletimError(:final message) => _buildError(message),
                  StudentBoletimLoaded(:final data) => _buildContent(data),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Boletim',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: _navy)),
                SizedBox(height: 2),
                Text('Notas e desempenho escolar',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ───────────────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF8E8E93), size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF8E8E93))),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<StudentBoletimCubit>().load(),
            child: const Text('Tentar novamente',
                style: TextStyle(color: _green)),
          ),
        ],
      ),
    );
  }

  // ── Content ─────────────────────────────────────────────────────────────────

  Widget _buildContent(StudentBoletimData data) {
    final cfg = data.config;
    final terms = data.terms.map((t) => t as Map<String, dynamic>).toList();

    // Agrupar termos por ano lectivo
    final Map<String, List<Map<String, dynamic>>> termsByYear = {};
    for (final t in terms) {
      final ano = (t['ano_nome'] ?? 'Ano Lectivo').toString();
      termsByYear.putIfAbsent(ano, () => []).add(t);
    }

    // Ano lectivo activo (do term seleccionado ou primeiro disponível)
    String? anoActivo;
    if (_termIndex < terms.length) {
      anoActivo = terms[_termIndex]['ano_nome']?.toString();
    }
    anoActivo ??= termsByYear.keys.firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildMediaCard(data.media, anoActivo, cfg),
          ),
          if (termsByYear.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTermGroups(termsByYear),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Notas por disciplina',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: _navy)),
                if (anoActivo != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(anoActivo,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8))),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildTable(data.grades, terms, cfg),
        ],
      ),
    );
  }

  // ── Média Geral Card ─────────────────────────────────────────────────────────

  Widget _buildMediaCard(double media, String? anoLectivo, BoletimConfig cfg) {
    final aprovado = media >= cfg.notaMinima;
    final mediaStr = media.toStringAsFixed(1).replaceAll('.', ',');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (anoLectivo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 5),
                  Text(anoLectivo,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_outlined,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Média Geral',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                    Text(mediaStr,
                        style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.1)),
                    Text('/ ${cfg.escalaMaxima.toInt()} valores',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    aprovado
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: aprovado ? AppColors.warning : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aprovado ? 'Aprovado' : 'Em Risco',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: aprovado ? AppColors.warning : AppColors.error),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Term Chips ────────────────────────────────────────────────────────────────

  Widget _buildTermGroups(Map<String, List<Map<String, dynamic>>> termsByYear) {
    // Índice global dos terms para manter _termIndex consistente
    final allTerms = termsByYear.values.expand((e) => e).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: termsByYear.entries.map((entry) {
        final anoNome = entry.key;
        final anoTerms = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label do ano lectivo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: Color(0xFF0369A1)),
                    const SizedBox(width: 5),
                    Text(anoNome,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0369A1))),
                  ],
                ),
              ),
              // Chips de períodos deste ano
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: anoTerms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final globalIdx = allTerms.indexOf(anoTerms[i]);
                    final selected = _termIndex == globalIdx;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _termIndex = globalIdx);
                        final termId = anoTerms[i]['id'] as int?;
                        context.read<StudentBoletimCubit>().load(
                          termId: termId != null && termId > 0 ? termId : null,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? _green : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? _green : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          (anoTerms[i]['nome'] ?? 'Período ${i + 1}').toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Grades Table ──────────────────────────────────────────────────────────────

  Widget _buildTable(
      List<dynamic> grades, List<Map<String, dynamic>> colTerms, BoletimConfig cfg) {
    if (grades.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Sem notas lançadas para este período.',
              style: TextStyle(color: Color(0xFF8E8E93))),
        ),
      );
    }

    const double wDisc = 160;
    const double wTerm = 68;
    const double wMedia = 62;
    const double wResult = 90;
    const double wFaltas = 52;
    final double totalW =
        wDisc + colTerms.length * wTerm + wMedia + wResult + wFaltas;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: totalW + 2, // +2 for 1px border on each side
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  _hCell('Disciplina', wDisc, align: TextAlign.left),
                  ...colTerms.map(
                      (t) => _hCell((t['nome'] ?? '').toString(), wTerm)),
                  _hCell('Média', wMedia),
                  _hCell('Resultado', wResult),
                  _hCell('Faltas', wFaltas),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            // Data rows
            ...grades.asMap().entries.map((entry) {
              final isLast = entry.key == grades.length - 1;
              final g = entry.value as Map<String, dynamic>;
              final nome = (g['nome'] ?? '—').toString();
              final notas = Map<String, dynamic>.from(
                  g['notas_por_periodo'] as Map? ?? {});
              final media = _toDouble(g['media']);
              final mediaStr = _fmtNota(g['media']);
              final hasGrades = media > 0;
              final aprovado = media >= cfg.notaMinima;
              final resultColor = hasGrades
                  ? (aprovado ? _green : _red)
                  : const Color(0xFF8E8E93);
              final resultLabel =
                  hasGrades ? (aprovado ? 'Aprovado' : 'Reprovado') : '—';

              return Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: wDisc,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(14, 0, 8, 0),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _subjectColor(nome),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(nome,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _navy),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ...colTerms.map((t) {
                          final tid = t['id']?.toString() ?? '';
                          final nota = notas[tid];
                          final notaD = _toDouble(nota);
                          final cor = notaD > 0
                              ? (notaD >= cfg.notaMinima ? _green : _red)
                              : const Color(0xFF8E8E93);
                          return _dCell(_fmtNota(nota), wTerm, color: cor);
                        }),
                        _dCell(mediaStr, wMedia,
                            color: hasGrades
                                ? (aprovado ? _green : _red)
                                : const Color(0xFF8E8E93)),
                        SizedBox(
                          width: wResult,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: resultColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(resultLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: resultColor)),
                            ),
                          ),
                        ),
                        _dCell('—', wFaltas),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: Color(0xFFF0F2F5)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _hCell(String label, double width,
      {TextAlign align = TextAlign.center}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(label,
            textAlign: align,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93))),
      ),
    );
  }

  Widget _dCell(String value, double width, {Color? color}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? _navy)),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  static String _fmtNota(dynamic value) {
    if (value == null) return '—';
    final d = _toDouble(value);
    if (d == 0.0) return '—';
    return d.toStringAsFixed(1).replaceAll('.', ',');
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
    if (lower.contains('fisica') || lower.contains('física')) {
      return const Color(0xFFF59E0B);
    }
    if (lower.contains('quimica') || lower.contains('química')) {
      return const Color(0xFFEC4899);
    }
    if (lower.contains('biologia')) return const Color(0xFF06B6D4);
    if (lower.contains('geografia')) return const Color(0xFF6366F1);
    if (lower.contains('historia') || lower.contains('história')) {
      return const Color(0xFFEF4444);
    }
    if (lower.contains('ingles') || lower.contains('inglês')) {
      return const Color(0xFF8B5CF6);
    }
    if (lower.contains('portug')) return const Color(0xFF3B82F6);
    if (lower.contains('desenho')) return const Color(0xFF14B8A6);
    if (lower.contains('informatica') || lower.contains('informática')) {
      return const Color(0xFF06B6D4);
    }
    if (lower.contains('planeamento') || lower.contains('ambiente')) {
      return const Color(0xFF22D3EE);
    }
    return const Color(0xFF64748B);
  }
}
