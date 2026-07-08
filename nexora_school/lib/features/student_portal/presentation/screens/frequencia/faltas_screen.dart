import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../cubit/student_presencas_cubit.dart';
import '../../cubit/student_presencas_state.dart';
import '../../../domain/repositories/student_portal_repository.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _red = Color(0xFFEF4444);

class FaltasScreen extends StatelessWidget {
  const FaltasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentPresencasCubit>()..load(),
      child: const _FaltasView(),
    );
  }
}

class _FaltasView extends StatefulWidget {
  const _FaltasView();

  @override
  State<_FaltasView> createState() => _FaltasViewState();
}

class _FaltasViewState extends State<_FaltasView> {
  _Filtro _filtro = _Filtro.todas;

  static const _icons = {
    'Matemática': Icons.calculate_outlined,
    'Física': Icons.bolt_outlined,
    'Química': Icons.science_outlined,
    'Biologia': Icons.eco_outlined,
    'História': Icons.history_edu_outlined,
    'Geografia': Icons.public_outlined,
    'Inglês': Icons.language_outlined,
    'Informática': Icons.computer_outlined,
    'Educação Física': Icons.sports_outlined,
    'Língua Portuguesa': Icons.menu_book_outlined,
  };

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Faltas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
        centerTitle: true,
      ),
      body: BlocBuilder<StudentPresencasCubit, StudentPresencasState>(
        builder: (context, state) {
          if (state is StudentPresencasLoading || state is StudentPresencasInitial) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is StudentPresencasError) {
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
                    onPressed: () => context.read<StudentPresencasCubit>().load(),
                    child: const Text('Tentar novamente',
                        style: TextStyle(color: _green)),
                  ),
                ],
              ),
            );
          }
          if (state is StudentPresencasLoaded) {
            final records = state.data.records;
            final faltas = records
                .whereType<Map<String, dynamic>>()
                .where((r) =>
                    r['estado'] == 'ausente' || r['estado'] == 'justificado')
                .toList();
            final porJustificar =
                faltas.where((f) => f['estado'] == 'ausente').toList();
            final justificadas =
                faltas.where((f) => f['estado'] == 'justificado').toList();

            final filtradas = switch (_filtro) {
              _Filtro.todas => faltas,
              _Filtro.porJustificar => porJustificar,
              _Filtro.justificadas => justificadas,
            };

            return Column(
              children: [
                _buildSummary(faltas.length, justificadas.length, porJustificar.length),
                _buildFiltros(),
                Expanded(
                  child: filtradas.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          itemCount: filtradas.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (_, i) =>
                              _buildFaltaCard(context, filtradas[i]),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummary(int total, int just, int porJust) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          _StatChip(value: total, label: 'Total', color: _navy),
          const SizedBox(width: 10),
          _StatChip(value: just, label: 'Justificadas', color: _green),
          const SizedBox(width: 10),
          _StatChip(value: porJust, label: 'Por justificar', color: _red),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: _Filtro.values.map((f) {
          final selected = f == _filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filtro = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? _green : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaltaCard(BuildContext context, Map<String, dynamic> f) {
    final isPorJust = f['estado'] == 'ausente';
    final iconColor = isPorJust ? _red : _green;
    final disciplina = (f['disciplina'] ?? '—').toString();
    final data = _formatDate(f['attendance_date']?.toString());
    final id = f['id']?.toString() ?? '';
    final icon = _icons[disciplina] ?? Icons.school_outlined;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(disciplina,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
                    const SizedBox(height: 2),
                    Text(data,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8E8E93))),
                  ],
                ),
              ),
              if (isPorJust)
                GestureDetector(
                  onTap: () => _showJustificarSheet(context, id, disciplina, data),
                  child: const Text('Justificar',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: _red)),
                )
              else
                const Text('Justificada',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _green)),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: _green.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('Sem faltas nesta categoria',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _navy)),
          const SizedBox(height: 6),
          const Text('Continue assim!',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }

  void _showJustificarSheet(
      BuildContext context, String id, String disciplina, String data) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          var loading = false;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Solicitar justificação',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
                const SizedBox(height: 4),
                Text('$disciplina  ·  $data',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14, color: _navy),
                  decoration: InputDecoration(
                    hintText: 'Descreva o motivo da falta...',
                    hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _green, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final motivo = ctrl.text.trim();
                            if (motivo.isEmpty) return;
                            setSheetState(() => loading = true);
                            try {
                              await sl<StudentPortalRepository>()
                                  .justificarFalta(id, motivo: motivo);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Justificação enviada com sucesso'),
                                    backgroundColor: _green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                context.read<StudentPresencasCubit>().load();
                              }
                            } catch (_) {
                              setSheetState(() => loading = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro ao enviar justificação'),
                                    backgroundColor: _red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Enviar pedido',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
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

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label, required this.color});
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }
}

enum _Filtro {
  todas('Todas'),
  porJustificar('Por justificar'),
  justificadas('Justificadas');

  const _Filtro(this.label);
  final String label;
}
