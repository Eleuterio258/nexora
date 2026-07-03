import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../core/constants/app_routes.dart';
import '../core/local/local_storage/i_local_storage.dart';
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
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _TeacherHomeTab(onLogout: _logout),
      const ClassListScreen(showBottomNav: true),
      const GradeEntryClassScreen(showBottomNav: true),
      const _MessagesPlaceholderTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: _TeacherBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _TeacherBottomNav extends StatelessWidget {
  const _TeacherBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Início'),
    (icon: Icons.groups_rounded, label: 'Turmas'),
    (icon: Icons.grade_rounded, label: 'Notas'),
    (icon: Icons.chat_bubble_outline_rounded, label: 'Mensagens'),
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
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
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

class _TeacherHomeTab extends StatelessWidget {
  const _TeacherHomeTab({required this.onLogout});

  final VoidCallback onLogout;

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStats(),
              const SizedBox(height: 28),
              _buildSectionTitle('Aulas de Hoje'),
              const SizedBox(height: 12),
              ..._aulas.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AulaCard(aula: a),
                  )),
              const SizedBox(height: 16),
              _buildSectionTitle('Pendências'),
              const SizedBox(height: 12),
              ..._pendencias.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PendenciaCard(pendencia: p),
                  )),
            ],
          ),
        ),
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
              'Olá, Prof. Silva!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'António Silva · Matemática e Física',
              style: TextStyle(fontSize: 13, color: _grey),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
              tooltip: 'Terminar sessão',
            ),
            const SizedBox(width: 4),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _green, width: 2),
              ),
              child: const Icon(Icons.person_rounded, color: _green, size: 26),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatCard(icon: Icons.groups_rounded, value: '6', label: 'Turmas'),
          const SizedBox(width: 10),
          _StatCard(icon: Icons.school_rounded, value: '142', label: 'Alunos'),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.assignment_rounded,
            value: '3',
            label: 'Tarefas Pendentes',
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.grade_rounded,
            value: '12',
            label: 'Notas por Lançar',
          ),
        ],
      ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _green,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: _grey),
          ),
        ],
      ),
    );
  }
}

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
            onTap: () => Navigator.pushNamed(context, '/attendance'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: _green),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Marcar Presenças',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _green),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendenciaCard extends StatelessWidget {
  const _PendenciaCard({required this.pendencia});

  final _Pendencia pendencia;

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
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: pendencia.cor, shape: BoxShape.circle),
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
                  style: TextStyle(fontSize: 12, color: pendencia.cor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesPlaceholderTab extends StatelessWidget {
  const _MessagesPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mensagens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Mensagens do professor\n(em desenvolvimento)',
          textAlign: TextAlign.center,
          style: TextStyle(color: _grey),
        ),
      ),
    );
  }
}

class _Aula {
  const _Aula({
    required this.hora,
    required this.disciplina,
    required this.turma,
    required this.sala,
    required this.alunos,
  });

  final String hora;
  final String disciplina;
  final String turma;
  final String sala;
  final int alunos;
}

class _Pendencia {
  const _Pendencia({required this.titulo, required this.prazo, required this.cor});

  final String titulo;
  final String prazo;
  final Color cor;
}
