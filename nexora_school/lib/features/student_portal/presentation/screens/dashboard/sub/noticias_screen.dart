import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../../cubit/student_noticias_cubit.dart';
import '../../../cubit/student_noticias_state.dart';
import '../../../../domain/entities/student_noticia.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class NoticiasScreen extends StatelessWidget {
  const NoticiasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentNoticiasCubit>()..load(),
      child: const _NoticiasView(),
    );
  }
}

class _NoticiasView extends StatelessWidget {
  const _NoticiasView();

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
            Text('Notícias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
            Text('Comunicados da escola',
                style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: BlocBuilder<StudentNoticiasCubit, StudentNoticiasState>(
        builder: (context, state) {
          if (state is StudentNoticiasLoading || state is StudentNoticiasInitial) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is StudentNoticiasError) {
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
                    onPressed: () => context.read<StudentNoticiasCubit>().load(),
                    child: const Text('Tentar novamente',
                        style: TextStyle(color: _green)),
                  ),
                ],
              ),
            );
          }
          if (state is StudentNoticiasLoaded) {
            final noticias = state.data.noticias;
            if (noticias.isEmpty) {
              return const Center(
                child: Text('Sem notícias de momento',
                    style: TextStyle(color: Color(0xFF8E8E93))),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: noticias.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _NoticiaCard(item: noticias[i]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  const _NoticiaCard({required this.item});
  final StudentNoticia item;

  static const _tipoColors = {
    'comunicado': Color(0xFF1565C0),
    'noticia': Color(0xFF00695C),
    'aviso': Color(0xFFF59E0B),
    'evento': Color(0xFF6750A4),
    'circular': Color(0xFFE65100),
  };

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _tipoColors[item.tipo] ?? const Color(0xFF8E8E93);
    final tag = item.tipo.isNotEmpty
        ? item.tipo[0].toUpperCase() + item.tipo.substring(1)
        : '—';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
                const SizedBox(height: 4),
                Text(_formatDate(item.publicadoEm),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(tag,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
