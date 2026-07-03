import 'package:flutter/material.dart';
import 'class_detail_teacher_screen.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class ClassListScreen extends StatelessWidget {
  const ClassListScreen({super.key, this.showBottomNav = false});

  final bool showBottomNav;

  static const _turmas = [
    _Turma(
      nome: '10ª Classe A',
      disciplina: 'Matemática',
      alunos: 28,
      assiduidade: '90%',
      media: '13.8',
      cor: Color(0xFF10B981),
    ),
    _Turma(
      nome: '10ª Classe B',
      disciplina: 'Matemática',
      alunos: 26,
      assiduidade: '88%',
      media: '12.5',
      cor: Color(0xFF14B8A6),
    ),
    _Turma(
      nome: '11ª Classe A',
      disciplina: 'Física',
      alunos: 24,
      assiduidade: '92%',
      media: '14.2',
      cor: Color(0xFF3B82F6),
    ),
    _Turma(
      nome: '11ª Classe B',
      disciplina: 'Física',
      alunos: 22,
      assiduidade: '85%',
      media: '11.9',
      cor: Color(0xFF6366F1),
    ),
    _Turma(
      nome: '12ª Classe A',
      disciplina: 'Matemática',
      alunos: 20,
      assiduidade: '94%',
      media: '15.1',
      cor: Color(0xFF8B5CF6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !showBottomNav,
        leading: showBottomNav
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Minhas Turmas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 20),
              ..._turmas.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _TurmaCard(turma: t),
                  )),
            ],
          ),
        ),
      ),
      floatingActionButton: showBottomNav
          ? null
          : FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: _green,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nova Turma', style: TextStyle(color: Colors.white)),
            ),
    );

    return content;
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Pesquisar turmas...',
          hintStyle: TextStyle(color: _grey, fontSize: 14),
          icon: Icon(Icons.search_rounded, color: _grey, size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return const Row(
      children: [
        _FilterChip(label: 'Todas', active: true),
        SizedBox(width: 8),
        _FilterChip(label: 'Manhã', active: false),
        SizedBox(width: 8),
        _FilterChip(label: 'Tarde', active: false),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? _green : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: active ? null : Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : _navy,
        ),
      ),
    );
  }
}

class _TurmaCard extends StatelessWidget {
  const _TurmaCard({required this.turma});

  final _Turma turma;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [turma.cor, turma.cor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      turma.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      turma.disciplina,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(icon: Icons.person_outline_rounded, value: '${turma.alunos} alunos'),
                    _InfoItem(icon: Icons.check_circle_outline_rounded, value: '${turma.assiduidade} Assiduidade'),
                    _InfoItem(icon: Icons.star_outline_rounded, value: 'Média: ${turma.media}'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClassDetailTeacherScreen(turma: turma.nome, disciplina: turma.disciplina),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Ver Alunos', style: TextStyle(color: _green, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/grade-entry-class'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Lançar Notas', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/attendance'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E5EA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Presenças', style: TextStyle(color: _navy, fontSize: 12)),
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

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _grey),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _navy),
        ),
      ],
    );
  }
}

class _Turma {
  const _Turma({
    required this.nome,
    required this.disciplina,
    required this.alunos,
    required this.assiduidade,
    required this.media,
    required this.cor,
  });

  final String nome;
  final String disciplina;
  final int alunos;
  final String assiduidade;
  final String media;
  final Color cor;
}
