import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../cubit/student_biblioteca_cubit.dart';
import '../../cubit/student_biblioteca_state.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class BibliotecaScreen extends StatelessWidget {
  const BibliotecaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentBibliotecaCubit>()..load(),
      child: const _BibliotecaView(),
    );
  }
}

class _BibliotecaView extends StatelessWidget {
  const _BibliotecaView();

  static const _statusColors = {
    'emprestado': Color(0xFFF59E0B),
    'devolvido': Color(0xFF00B87A),
    'atrasado': Color(0xFFEF4444),
    'reservado': Color(0xFF6750A4),
  };

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Biblioteca',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
            Text('Histórico de empréstimos',
                style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: BlocBuilder<StudentBibliotecaCubit, StudentBibliotecaState>(
        builder: (context, state) {
          if (state is StudentBibliotecaLoading || state is StudentBibliotecaInitial) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is StudentBibliotecaError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFF8E8E93), size: 40),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Color(0xFF8E8E93))),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        context.read<StudentBibliotecaCubit>().load(),
                    child: const Text('Tentar novamente',
                        style: TextStyle(color: _green)),
                  ),
                ],
              ),
            );
          }
          if (state is StudentBibliotecaLoaded) {
            final records = state.records;
            if (records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined,
                        size: 64,
                        color: _green.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text('Sem empréstimos registados',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _navy)),
                    const SizedBox(height: 6),
                    const Text('Os seus empréstimos aparecerão aqui',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final r = records[i] as Map<String, dynamic>;
                final titulo = (r['livro_titulo'] ?? 'Livro desconhecido').toString();
                final autor = (r['livro_autor'] ?? '').toString();
                final categoria = (r['livro_categoria'] ?? '').toString();
                final status = (r['status'] ?? 'emprestado').toString();
                final statusColor =
                    _statusColors[status] ?? const Color(0xFF8E8E93);
                final statusLabel =
                    status[0].toUpperCase() + status.substring(1);
                final emprestadoEm = _formatDate(r['emprestado_em']?.toString());
                final devolucao = _formatDate(r['data_devolucao']?.toString());

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 58,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.book_outlined,
                            color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(titulo,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _navy),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(statusLabel,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor)),
                                ),
                              ],
                            ),
                            if (autor.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(autor,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF8E8E93))),
                            ],
                            if (categoria.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(categoria,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF8E8E93))),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 12, color: Color(0xFFADB5BD)),
                                const SizedBox(width: 4),
                                Text('Empréstimo: $emprestadoEm',
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0xFF8E8E93))),
                                if (devolucao != '—') ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.assignment_return_outlined,
                                      size: 12, color: Color(0xFFADB5BD)),
                                  const SizedBox(width: 4),
                                  Text('Devolução: $devolucao',
                                      style: TextStyle(
                                          fontSize: 11, color: statusColor)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
