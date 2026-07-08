import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../../cubit/student_turma_cubit.dart';
import '../../../cubit/student_turma_state.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class TurmaScreen extends StatelessWidget {
  const TurmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentTurmaCubit>()..load(),
      child: const _TurmaView(),
    );
  }
}

class _TurmaView extends StatefulWidget {
  const _TurmaView();

  @override
  State<_TurmaView> createState() => _TurmaViewState();
}

class _TurmaViewState extends State<_TurmaView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Turma',
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
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(icon: Icon(Icons.school_outlined, size: 16), text: 'Docentes'),
              Tab(icon: Icon(Icons.people_outline_rounded, size: 16), text: 'Alunos'),
            ],
          ),
        ),
      ),
      body: BlocBuilder<StudentTurmaCubit, StudentTurmaState>(
        builder: (context, state) {
          if (state is StudentTurmaLoading || state is StudentTurmaInitial) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          if (state is StudentTurmaError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<StudentTurmaCubit>().load(),
            );
          }
          if (state is StudentTurmaLoaded) {
            return _TurmaContent(data: state.data, tabController: _tabController);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TurmaContent extends StatelessWidget {
  const _TurmaContent({required this.data, required this.tabController});
  final dynamic data;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final turma = data.turma as Map<String, dynamic>;
    final docentes = data.docentes as List<dynamic>;
    final alunos = data.alunos as List<dynamic>;

    final nome = (turma['nome'] ?? '—').toString();
    final serie = (turma['serie'] ?? '').toString();
    final sala = (turma['sala'] ?? '').toString();
    final director = (turma['director_turma'] ?? '').toString();
    final anoLectivo = (turma['ano_lectivo'] ?? '').toString();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _SectionCard(
            color: const Color(0xFF1565C0),
            icon: Icons.groups_outlined,
            title: serie.isNotEmpty ? '$serie — $nome' : nome,
            subtitle: '${alunos.length} alunos${anoLectivo.isNotEmpty ? ' · $anoLectivo' : ''}',
            rows: [
              if (director.isNotEmpty)
                _InfoRow(icon: Icons.person_outlined, label: 'Director de turma', value: director),
              if (sala.isNotEmpty)
                _InfoRow(icon: Icons.location_on_outlined, label: 'Sala', value: sala),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _DocentesTab(docentes: docentes),
              _AlunosTab(alunos: alunos),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocentesTab extends StatelessWidget {
  const _DocentesTab({required this.docentes});
  final List<dynamic> docentes;

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
    'Arte': Icons.brush_outlined,
    'Música': Icons.music_note_outlined,
    'Redação': Icons.edit_outlined,
  };

  static const _palette = [
    Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6),
    Color(0xFFF59E0B), Color(0xFF06B6D4), Color(0xFFEC4899),
    Color(0xFFEF4444), Color(0xFF14B8A6), Color(0xFF6366F1),
    Color(0xFFF97316), Color(0xFF0EA5E9), Color(0xFF84CC16),
  ];

  @override
  Widget build(BuildContext context) {
    if (docentes.isEmpty) {
      return const Center(
        child: Text('Sem docentes registados', style: TextStyle(color: Color(0xFF8E8E93))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: docentes.length,
      itemBuilder: (_, i) {
        final d = docentes[i] as Map<String, dynamic>;
        final disciplina = (d['disciplina'] ?? '').toString();
        final professor = (d['professor'] ?? '').toString();
        final icon = _icons[disciplina] ?? Icons.school_outlined;
        final color = _palette[i % _palette.length];
        return _ListRow(
          icon: icon,
          iconColor: color,
          title: professor.isNotEmpty ? professor : disciplina,
          subtitle: professor.isNotEmpty ? disciplina : '',
          isLast: i == docentes.length - 1,
        );
      },
    );
  }
}

class _AlunosTab extends StatelessWidget {
  const _AlunosTab({required this.alunos});
  final List<dynamic> alunos;

  @override
  Widget build(BuildContext context) {
    final comCargo = alunos
        .map((a) => a as Map<String, dynamic>)
        .where((a) => (a['cargo'] ?? '').toString().isNotEmpty)
        .toList();
    final semCargo = alunos
        .map((a) => a as Map<String, dynamic>)
        .where((a) => (a['cargo'] ?? '').toString().isEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (comCargo.isNotEmpty) ...[
          _SectionCard(
            color: const Color(0xFFF59E0B),
            icon: Icons.workspace_premium_outlined,
            title: 'Cargos da Turma',
            subtitle: '${comCargo.length} representantes',
            rows: List.generate(comCargo.length, (i) {
              final a = comCargo[i];
              final cargo = (a['cargo'] ?? '').toString();
              return _ListRow(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: (a['nome'] ?? '').toString(),
                subtitle: cargo,
                isLast: i == comCargo.length - 1,
              );
            }),
          ),
          const SizedBox(height: 20),
        ],
        _SectionCard(
          color: const Color(0xFF8E8E93),
          icon: Icons.people_outline_rounded,
          title: 'Restantes Alunos',
          subtitle: '${semCargo.length} alunos',
          rows: List.generate(semCargo.length, (i) {
            final a = semCargo[i];
            final codigo = (a['codigo'] ?? (i + 1).toString().padLeft(2, '0')).toString();
            return _NumberRow(
              numero: codigo,
              nome: (a['nome'] ?? '').toString(),
              isLast: i == semCargo.length - 1,
            );
          }),
        ),
      ],
    );
  }
}

// ── Widgets partilhados ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF8E8E93), size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF8E8E93))),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente', style: TextStyle(color: _green)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rows,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: _navy)),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...rows,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFADB5BD)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _navy),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, isLast ? 4 : 0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(fontSize: 11, color: iconColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.numero, required this.nome, required this.isLast});
  final String numero;
  final String nome;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, isLast ? 4 : 0),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(numero,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFADB5BD))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(nome,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _navy)),
          ),
        ],
      ),
    );
  }
}
