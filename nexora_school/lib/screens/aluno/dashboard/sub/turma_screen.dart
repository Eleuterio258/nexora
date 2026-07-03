import 'package:flutter/material.dart';
import 'chat_screen.dart';

const _navy = Color(0xFF0D1B2A);

class TurmaScreen extends StatefulWidget {
  const TurmaScreen({super.key});

  @override
  State<TurmaScreen> createState() => _TurmaScreenState();
}

class _TurmaScreenState extends State<TurmaScreen>
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

  static const _cargos = [
    _Cargo(
      nome: 'Ana Beatriz Machava',
      cargo: 'Delegada de Turma',
      icon: Icons.star_rounded,
      color: Color(0xFFF59E0B),
    ),
    _Cargo(
      nome: 'Bruno Silva Tembe',
      cargo: 'Sub-delegado',
      icon: Icons.star_half_rounded,
      color: Color(0xFF6750A4),
    ),
    _Cargo(
      nome: 'Carlos Muianga',
      cargo: 'Representante Cultural',
      icon: Icons.palette_outlined,
      color: Color(0xFF1565C0),
    ),
    _Cargo(
      nome: 'Diana Nhamposse',
      cargo: 'Representante Desportivo',
      icon: Icons.sports_soccer_outlined,
      color: Color(0xFF00695C),
    ),
  ];

  static const _top = [
    _Aluno(nome: 'Ana Beatriz Machava', numero: '01', avg: '9,2'),
    _Aluno(nome: 'Bruno Silva Tembe', numero: '02', avg: '8,8'),
    _Aluno(nome: 'Carlos Muianga', numero: '03', avg: '8,6'),
  ];

  static const _restantes = [
    _Aluno(nome: 'Diana Nhamposse', numero: '04', avg: '—'),
    _Aluno(nome: 'Eduardo Cossa', numero: '05', avg: '—'),
    _Aluno(nome: 'Fátima Bila', numero: '06', avg: '—'),
    _Aluno(nome: 'Gilberto Mondlane', numero: '07', avg: '—'),
    _Aluno(nome: 'Helena Sitoe', numero: '08', avg: '—'),
    _Aluno(nome: 'Ivo Macuácua', numero: '09', avg: '—'),
    _Aluno(nome: 'Joana Cumbane', numero: '10', avg: '—'),
    _Aluno(nome: 'Kwame Nhantumbo', numero: '11', avg: '—'),
    _Aluno(nome: 'Laura Fumo', numero: '12', avg: '—'),
    _Aluno(nome: 'Manuel Cossa', numero: '13', avg: '—'),
  ];

  static const _docentes = [
    _Docente(
      nome: 'Prof. Rafael Souza',
      disciplina: 'Matemática',
      icon: Icons.calculate_outlined,
      color: Color(0xFF10B981),
    ),
    _Docente(
      nome: 'Profa. Ana Lima',
      disciplina: 'Língua Portuguesa',
      icon: Icons.menu_book_outlined,
      color: Color(0xFF3B82F6),
    ),
    _Docente(
      nome: 'Prof. Carlos Santos',
      disciplina: 'Inglês',
      icon: Icons.language_outlined,
      color: Color(0xFF8B5CF6),
    ),
    _Docente(
      nome: 'Prof. Hélio Nunes',
      disciplina: 'Física',
      icon: Icons.bolt_outlined,
      color: Color(0xFFF59E0B),
    ),
    _Docente(
      nome: 'Profa. Maria João',
      disciplina: 'Biologia',
      icon: Icons.eco_outlined,
      color: Color(0xFF06B6D4),
    ),
    _Docente(
      nome: 'Prof. Thiago Martins',
      disciplina: 'Química',
      icon: Icons.science_outlined,
      color: Color(0xFFEC4899),
    ),
    _Docente(
      nome: 'Prof. Marcos Vinicius',
      disciplina: 'História',
      icon: Icons.history_edu_outlined,
      color: Color(0xFFEF4444),
    ),
    _Docente(
      nome: 'Prof. Armando Costa',
      disciplina: 'Ed. Física',
      icon: Icons.sports_outlined,
      color: Color(0xFF14B8A6),
    ),
    _Docente(
      nome: 'Profa. Camila Ferreira',
      disciplina: 'Geografia',
      icon: Icons.public_outlined,
      color: Color(0xFF6366F1),
    ),
    _Docente(
      nome: 'Profa. Juliana Alves',
      disciplina: 'Redação',
      icon: Icons.edit_outlined,
      color: Color(0xFFF97316),
    ),
    _Docente(
      nome: 'Prof. André Castilho',
      disciplina: 'Informática',
      icon: Icons.computer_outlined,
      color: Color(0xFF0EA5E9),
    ),
  ];

  static const _rankColors = [
    Color(0xFFF59E0B),
    Color(0xFF8E8E93),
    Color(0xFFCD7F32),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _navy,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Turma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF10B981),
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: const Color(0xFFADB5BD),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.school_outlined, size: 16),
                    text: 'Docentes',
                  ),
                  Tab(
                    icon: Icon(Icons.people_outline_rounded, size: 16),
                    text: 'Alunos',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Info da turma (partilhada entre tabs) ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SemanaSection(
              headerColor: const Color(0xFF1565C0),
              headerIcon: Icons.groups_outlined,
              headerAbbr: '12A',
              headerTitle: '12.ª Classe — Turma A',
              headerSub: '28 alunos  ·  Sala 204',
              rows: const [
                _InfoRow(
                  icon: Icons.person_outlined,
                  label: 'Director de turma',
                  value: 'Prof. Rafael Souza',
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Sala',
                  value: '204 — Bloco B',
                ),
                _InfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Turno',
                  value: 'Manhã — 07:30 às 13:00',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── TabBarView ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Docentes
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: _docentes.length,
                  itemBuilder: (_, i) => _DocenteRow(
                    item: _docentes[i],
                    isLast: i == _docentes.length - 1,
                  ),
                ),
                // Tab Alunos
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _SemanaSection(
                      headerColor: const Color(0xFFF59E0B),
                      headerIcon: Icons.workspace_premium_outlined,
                      headerAbbr: 'CGO',
                      headerTitle: 'Cargos da Turma',
                      headerSub: '${_cargos.length} representantes',
                      rows: List.generate(
                        _cargos.length,
                        (i) => _CargoRow(
                          item: _cargos[i],
                          isLast: i == _cargos.length - 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SemanaSection(
                      headerColor: _rankColors[0],
                      headerIcon: Icons.emoji_events_outlined,
                      headerAbbr: 'TOP',
                      headerTitle: 'Melhores da Turma',
                      headerSub: 'Top ${_top.length} alunos',
                      rows: List.generate(
                        _top.length,
                        (i) => _TopRow(
                          aluno: _top[i],
                          rank: i + 1,
                          isLast: i == _top.length - 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SemanaSection(
                      headerColor: const Color(0xFF8E8E93),
                      headerIcon: Icons.people_outline_rounded,
                      headerAbbr: 'ALU',
                      headerTitle: 'Restantes Alunos',
                      headerSub: '${_restantes.length} alunos · Confidencial',
                      rows: List.generate(
                        _restantes.length,
                        (i) => _RestanteRow(
                          aluno: _restantes[i],
                          isLast: i == _restantes.length - 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Secção estilo Semana ───────────────────────────────────────────────────────

class _SemanaSection extends StatelessWidget {
  const _SemanaSection({
    required this.headerColor,
    required this.headerIcon,
    required this.headerAbbr,
    required this.headerTitle,
    required this.headerSub,
    required this.rows,
  });

  final Color headerColor;
  final IconData headerIcon;
  final String headerAbbr;
  final String headerTitle;
  final String headerSub;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — igual ao dia do agenda semana
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: headerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(headerIcon, size: 22, color: headerColor),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headerTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  Text(
                    headerSub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Linhas flat — igual ao SemanaRow
        ...rows,
      ],
    );
  }
}

// ── Linhas flat ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
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
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _CargoRow extends StatelessWidget {
  const _CargoRow({required this.item, required this.isLast});
  final _Cargo item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(nome: item.nome, sub: item.cargo),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, isLast ? 4 : 0),
        child: Row(
          children: [
            Icon(item.icon, size: 16, color: item.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nome,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  Text(
                    item.cargo,
                    style: TextStyle(fontSize: 11, color: item.color),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCBD5E0)),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.aluno,
    required this.rank,
    required this.isLast,
  });
  final _Aluno aluno;
  final int rank;
  final bool isLast;

  static const _rankColors = [
    Color(0xFFF59E0B),
    Color(0xFF8E8E93),
    Color(0xFFCD7F32),
  ];
  static const _rankLabels = ['1°', '2°', '3°'];

  @override
  Widget build(BuildContext context) {
    final color = _rankColors[rank - 1];
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(nome: aluno.nome, sub: 'Colega de Turma'),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, isLast ? 4 : 0),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                _rankLabels[rank - 1],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                aluno.nome,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
            ),
            Text(
              aluno.avg,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 14,
              color: Color(0xFFCBD5E0),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestanteRow extends StatelessWidget {
  const _RestanteRow({required this.aluno, required this.isLast});
  final _Aluno aluno;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(nome: aluno.nome, sub: 'Colega de Turma'),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, isLast ? 4 : 0),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                aluno.numero,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFADB5BD),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                aluno.nome,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _navy,
                ),
              ),
            ),
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 14,
              color: Color(0xFFCBD5E0),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _Cargo {
  const _Cargo({
    required this.nome,
    required this.cargo,
    required this.icon,
    required this.color,
  });
  final String nome, cargo;
  final IconData icon;
  final Color color;
}

class _Aluno {
  const _Aluno({required this.nome, required this.numero, required this.avg});
  final String nome, numero, avg;
}

class _Docente {
  const _Docente({
    required this.nome,
    required this.disciplina,
    required this.icon,
    required this.color,
  });
  final String nome, disciplina;
  final IconData icon;
  final Color color;
}

// ── DocenteRow ─────────────────────────────────────────────────────────────────

class _DocenteRow extends StatelessWidget {
  const _DocenteRow({required this.item, required this.isLast});
  final _Docente item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(nome: item.nome, sub: item.disciplina),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, isLast ? 4 : 0),
        child: Row(
          children: [
            Icon(item.icon, size: 16, color: item.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nome,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  Text(
                    item.disciplina,
                    style: TextStyle(fontSize: 11, color: item.color),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 14,
              color: Color(0xFFCBD5E0),
            ),
          ],
        ),
      ),
    );
  }
}
