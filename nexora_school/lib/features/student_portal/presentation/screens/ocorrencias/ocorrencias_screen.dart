import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../cubit/student_ocorrencias_cubit.dart';
import '../../cubit/student_ocorrencias_state.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class OcorrenciasScreen extends StatelessWidget {
  const OcorrenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentOcorrenciasCubit>()..load(),
      child: const _OcorrenciasView(),
    );
  }
}

class _OcorrenciasView extends StatefulWidget {
  const _OcorrenciasView();

  @override
  State<_OcorrenciasView> createState() => _OcorrenciasViewState();
}

class _OcorrenciasViewState extends State<_OcorrenciasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Ocorrências',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: TabBar(
            controller: _tabController,
            indicatorColor: _green,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: _green,
            unselectedLabelColor: const Color(0xFFADB5BD),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Incidentes'),
              Tab(text: 'Sanções'),
              Tab(text: 'Méritos'),
            ],
          ),
        ),
      ),
      body: BlocBuilder<StudentOcorrenciasCubit, StudentOcorrenciasState>(
        builder: (context, state) {
          if (state is StudentOcorrenciasLoading ||
              state is StudentOcorrenciasInitial) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is StudentOcorrenciasError) {
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
                    onPressed: () =>
                        context.read<StudentOcorrenciasCubit>().load(),
                    child: const Text('Tentar novamente',
                        style: TextStyle(color: _green)),
                  ),
                ],
              ),
            );
          }
          if (state is StudentOcorrenciasLoaded) {
            final incidentes =
                state.data['incidentes'] as List<dynamic>? ?? [];
            final sancoes = state.data['sancoes'] as List<dynamic>? ?? [];
            final meritos = state.data['meritos'] as List<dynamic>? ?? [];

            return TabBarView(
              controller: _tabController,
              children: [
                _OcorrenciasList(
                  items: incidentes,
                  icon: Icons.warning_amber_outlined,
                  color: const Color(0xFFEF4444),
                  emptyLabel: 'Sem incidentes registados',
                  titleKey: 'tipo',
                  dateKey: 'data_ocorrencia',
                  subtitleKey: 'descricao',
                ),
                _OcorrenciasList(
                  items: sancoes,
                  icon: Icons.gavel_outlined,
                  color: const Color(0xFFF59E0B),
                  emptyLabel: 'Sem sanções registadas',
                  titleKey: 'tipo',
                  dateKey: 'data_inicio',
                  subtitleKey: 'descricao',
                ),
                _OcorrenciasList(
                  items: meritos,
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFF10B981),
                  emptyLabel: 'Sem méritos registados',
                  titleKey: 'descricao',
                  dateKey: 'data_merito',
                  subtitleKey: 'pontos',
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OcorrenciasList extends StatelessWidget {
  const _OcorrenciasList({
    required this.items,
    required this.icon,
    required this.color,
    required this.emptyLabel,
    required this.titleKey,
    required this.dateKey,
    required this.subtitleKey,
  });

  final List<dynamic> items;
  final IconData icon;
  final Color color;
  final String emptyLabel;
  final String titleKey;
  final String dateKey;
  final String subtitleKey;

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = items[i] as Map<String, dynamic>;
        final title = (item[titleKey] ?? '—').toString();
        final date = _formatDate(item[dateKey]?.toString());
        final sub = item[subtitleKey]?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(sub,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8E8E93)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (date.isNotEmpty)
                Text(date,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8E8E93))),
            ],
          ),
        );
      },
    );
  }
}
