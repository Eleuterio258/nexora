import 'package:flutter/material.dart';
import 'student_file_teacher_screen.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class ClassDetailTeacherScreen extends StatefulWidget {
  const ClassDetailTeacherScreen({super.key, required this.turma, required this.disciplina});

  final String turma;
  final String disciplina;

  @override
  State<ClassDetailTeacherScreen> createState() => _ClassDetailTeacherScreenState();
}

class _ClassDetailTeacherScreenState extends State<ClassDetailTeacherScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final _alunos = List.generate(
    28,
    (i) => _Aluno(
      nome: _nomes[i % _nomes.length],
      numero: '${i + 1}'.padLeft(2, '0'),
      media: _medias[i % _medias.length],
      assiduidade: _assiduidades[i % _assiduidades.length],
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: Text(
          '${widget.turma} — ${widget.disciplina}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: _navy),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              TabBar(
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
                  Tab(text: 'Alunos'),
                  Tab(text: 'Notas'),
                  Tab(text: 'Tarefas'),
                  Tab(text: 'Comunicados'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(child: _StatBox(value: '28', label: 'Alunos', icon: Icons.person_outline_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(value: '13.8', label: 'Média', icon: Icons.star_outline_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(value: '90%', label: 'Assiduidade', icon: Icons.check_circle_outline_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlunosTab(),
                _buildPlaceholder('Notas da turma'),
                _buildPlaceholder('Tarefas da turma'),
                _buildPlaceholder('Comunicados da turma'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlunosTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar aluno...',
              hintStyle: TextStyle(color: _grey, fontSize: 14),
              icon: Icon(Icons.search_rounded, color: _grey, size: 22),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Em Risco · 3',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sort_rounded, color: _green, size: 18),
              label: const Text('Ordenar', style: TextStyle(color: _green, fontSize: 13)),
            ),
          ],
        ),
        ..._alunos.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AlunoRow(aluno: a, disciplina: widget.disciplina),
            )),
      ],
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: _grey),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _green, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _grey),
          ),
        ],
      ),
    );
  }
}

class _AlunoRow extends StatelessWidget {
  const _AlunoRow({required this.aluno, required this.disciplina});

  final _Aluno aluno;
  final String disciplina;

  @override
  Widget build(BuildContext context) {
    final media = double.tryParse(aluno.media.replaceAll(',', '.')) ?? 0;
    final corMedia = media >= 10 ? _green : Colors.redAccent;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentFileTeacherScreen(
            nome: aluno.nome,
            numero: aluno.numero,
            turma: '10ª A',
            disciplina: disciplina,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: media < 10 ? Colors.red.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _green.withValues(alpha: 0.1),
              child: Text(
                aluno.nome.split(' ').map((p) => p[0]).take(2).join(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _green),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aluno.nome,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _navy),
                  ),
                  Text(
                    'Nº ${aluno.numero}',
                    style: const TextStyle(fontSize: 12, color: _grey),
                  ),
                ],
              ),
            ),
            Text(
              aluno.media,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: corMedia),
            ),
            const SizedBox(width: 8),
            Text(
              '${aluno.assiduidade}%',
              style: const TextStyle(fontSize: 12, color: _grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aluno {
  const _Aluno({required this.nome, required this.numero, required this.media, required this.assiduidade});

  final String nome;
  final String numero;
  final String media;
  final String assiduidade;
}

const _nomes = [
  'Ana Beatriz Machava',
  'Bruno Silva Tembe',
  'Carlos Muianga',
  'Diana Nhamposse',
  'Eduardo Cossa',
  'Fátima Bila',
  'Gilberto Mondlane',
  'Helena Sitoe',
];

const _medias = ['15.7', '8.5', '12.3', '16.0', '9.8', '14.2', '11.5', '17.3'];
const _assiduidades = ['92', '85', '88', '95', '78', '90', '87', '96'];
