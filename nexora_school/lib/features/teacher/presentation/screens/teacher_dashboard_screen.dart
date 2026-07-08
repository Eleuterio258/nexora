import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nexora_school/core/constants/app_routes.dart';
import 'package:nexora_school/core/local/local_storage/i_local_storage.dart';
import 'class_list_screen.dart';
import 'grade_entry_class_screen.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _currentIndex = 0;

  void _logout() async {
    await GetIt.instance<ILocalStorage>().clear();
    if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _TeacherHomeTab(onTabSwitch: (i) => setState(() => _currentIndex = i)),
      const ClassListScreen(showBottomNav: true),
      const GradeEntryClassScreen(showBottomNav: true),
      const _MessagesTab(),
      _TeacherPerfilTab(onLogout: _logout),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom Nav ──────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Início'),
    (icon: Icons.groups_rounded, label: 'Turmas'),
    (icon: Icons.grade_rounded, label: 'Notas'),
    (icon: Icons.chat_bubble_outline_rounded, label: 'Mensagens'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == currentIndex;
              final item = _items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (active)
                        Container(
                          width: 40,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else
                        const SizedBox(height: 7),
                      Icon(item.icon, color: active ? _green : _grey, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: active ? _green : _grey,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ────────────────────────────────────────────────────────────────────

class _TeacherHomeTab extends StatelessWidget {
  const _TeacherHomeTab({required this.onTabSwitch});

  final ValueChanged<int> onTabSwitch;

  static const _aulas = [
    _Aula(
      hora: '08h00–09h30',
      disciplina: 'Matemática',
      turma: '10ª A',
      sala: 'Sala 12',
      alunos: 28,
    ),
    _Aula(
      hora: '10h00–11h30',
      disciplina: 'Física',
      turma: '11ª B',
      sala: 'Sala 8',
      alunos: 24,
    ),
  ];

  static const _pendencias = [
    _Pendencia(
      titulo: 'Notas do Teste 2 — Física 11ª B',
      prazo: 'Entregar até amanhã',
      cor: Color(0xFFF59E0B),
    ),
    _Pendencia(
      titulo: 'Presenças de Matemática 10ª A',
      prazo: 'Hoje · 09h30',
      cor: _green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(160, 160),
              painter: _BlobPainter(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildResumoCard(),
                  const SizedBox(height: 24),
                  _buildQuickAccess(context),
                  const SizedBox(height: 28),
                  _buildStats(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Aulas de Hoje'),
                  const SizedBox(height: 12),
                  ..._aulas.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AulaCard(aula: a),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Pendências'),
                  const SizedBox(height: 12),
                  ..._pendencias.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PendenciaCard(pendencia: p),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Início',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Bom dia, Prof. Silva',
              style: TextStyle(fontSize: 13, color: _grey),
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: _navy,
                size: 22,
              ),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResumoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A36C), Color(0xFF00C98A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOJE',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '2 Aulas',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 56, color: Colors.white24),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALUNOS',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '142',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '3 notas por lançar e 1 presença em falta.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
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

  Widget _buildQuickAccess(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickCard(
            icon: Icons.groups_rounded,
            label: 'Turmas',
            color: const Color(0xFF1565C0),
            onTap: () => onTabSwitch(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickCard(
            icon: Icons.how_to_reg_rounded,
            label: 'Presenças',
            color: const Color(0xFFE65100),
            onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickCard(
            icon: Icons.campaign_rounded,
            label: 'Comunicados',
            color: const Color(0xFF6750A4),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.createAnnouncement),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    const divider = Color(0xFFEEEEF0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo do Professor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: _StatItem(
                icon: Icons.groups_rounded,
                iconColor: _green,
                value: '6',
                valueColor: _green,
                label: 'Turmas',
                sub: 'activas',
              ),
            ),
            Container(width: 1, height: 72, color: divider),
            const Expanded(
              child: _StatItem(
                icon: Icons.school_rounded,
                iconColor: Color(0xFF6B4EFF),
                value: '142',
                valueColor: Color(0xFF6B4EFF),
                label: 'Alunos',
                sub: 'total',
              ),
            ),
          ],
        ),
        const Divider(height: 1, color: divider),
        const SizedBox(height: 4),
        Row(
          children: [
            const Expanded(
              child: _StatItem(
                icon: Icons.assignment_rounded,
                iconColor: Color(0xFF3B82F6),
                value: '3',
                valueColor: Color(0xFF3B82F6),
                label: 'Tarefas',
                sub: 'pendentes',
              ),
            ),
            Container(width: 1, height: 72, color: divider),
            const Expanded(
              child: _StatItem(
                icon: Icons.grade_rounded,
                iconColor: Color(0xFFF59E0B),
                value: '12',
                valueColor: Color(0xFFF59E0B),
                label: 'Notas',
                sub: 'por lançar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _navy,
      ),
    );
  }
}

// ── Quick card ──────────────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat item ───────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor, valueColor;
  final String value, label, sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(sub, style: const TextStyle(fontSize: 11, color: _grey)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Aula card ───────────────────────────────────────────────────────────────────

class _AulaCard extends StatelessWidget {
  const _AulaCard({required this.aula});

  final _Aula aula;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  aula.hora.split('–').first,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
                Container(
                  width: 32,
                  height: 1,
                  color: _green.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
                Text(
                  aula.hora.split('–').last,
                  style: const TextStyle(fontSize: 12, color: _green),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${aula.disciplina} · ${aula.turma}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${aula.sala} · ${aula.alunos} alunos',
                  style: const TextStyle(fontSize: 13, color: _grey),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: _green),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Marcar Presenças',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pendência card ──────────────────────────────────────────────────────────────

class _PendenciaCard extends StatelessWidget {
  const _PendenciaCard({required this.pendencia});

  final _Pendencia pendencia;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pendencia.cor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: pendencia.cor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pendencia.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pendencia.prazo,
                  style: TextStyle(
                    fontSize: 12,
                    color: pendencia.cor,
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
}

// ── Messages Tab ────────────────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Mensagens',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Comunicação com alunos e pais',
                style: TextStyle(fontSize: 13, color: _grey),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Em desenvolvimento',
                    style: TextStyle(color: _grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Perfil Tab ──────────────────────────────────────────────────────────────────

class _TeacherPerfilTab extends StatelessWidget {
  const _TeacherPerfilTab({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(160, 160),
              painter: _BlobPainter(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perfil',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Informações e preferências',
                    style: TextStyle(fontSize: 13, color: _grey),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildSection('Conta', [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Editar perfil',
                      subtitle: 'Actualize as suas informações pessoais',
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Segurança',
                      subtitle: 'Altere a sua senha e configurações',
                    ),
                    _MenuItem(
                      icon: Icons.schedule_outlined,
                      title: 'Horários',
                      subtitle: 'Veja os seus horários de aula',
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Preferências', [
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notificações',
                      subtitle: 'Escolha como deseja receber avisos',
                    ),
                    _MenuItem(
                      icon: Icons.palette_outlined,
                      title: 'Aparência',
                      subtitle: 'Personalize o tema da aplicação',
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Suporte', [
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Ajuda e FAQ',
                      subtitle: 'Tire as suas dúvidas',
                    ),
                    _MenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Fale connosco',
                      subtitle: 'Entre em contacto com a nossa equipa',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sair da conta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: _green, size: 40),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'António Silva',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              SizedBox(height: 2),
              Text('Professor', style: TextStyle(fontSize: 13, color: _grey)),
              SizedBox(height: 2),
              Text(
                'Matemática e Física',
                style: TextStyle(fontSize: 13, color: _navy),
              ),
              SizedBox(height: 2),
              Text(
                'professor@nexora.mz',
                style: TextStyle(fontSize: 13, color: _grey),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.school_outlined, color: _green, size: 22),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(e.value.icon, color: _green, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _navy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.value.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E0),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: Color(0xFFF0F2F5),
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ── Blob painter ────────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00B87A).withValues(alpha: 0.06);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.2, 0)
      ..cubicTo(0, 0, 0, size.height * 0.3, size.width * 0.1, size.height * 0.6)
      ..cubicTo(
        size.width * 0.2,
        size.height,
        size.width * 0.7,
        size.height,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Data classes ────────────────────────────────────────────────────────────────

class _Aula {
  const _Aula({
    required this.hora,
    required this.disciplina,
    required this.turma,
    required this.sala,
    required this.alunos,
  });
  final String hora, disciplina, turma, sala;
  final int alunos;
}

class _Pendencia {
  const _Pendencia({
    required this.titulo,
    required this.prazo,
    required this.cor,
  });
  final String titulo, prazo;
  final Color cor;
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
}
