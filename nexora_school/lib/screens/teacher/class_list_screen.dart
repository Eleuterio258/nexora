import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';

const _green = Color(0xFF00B87A);
const _navy  = Color(0xFF0D1B2A);
const _grey  = Color(0xFF8E8E93);

class ClassListScreen extends StatelessWidget {
  const ClassListScreen({super.key, this.showBottomNav = false});

  final bool showBottomNav;

  static const _turmas = [
    _Turma(nome: '10ª Classe A', disciplina: 'Matemática', alunos: 28, sala: 'Sala 12', pendentes: 3),
    _Turma(nome: '10ª Classe B', disciplina: 'Matemática', alunos: 26, sala: 'Sala 7',  pendentes: 0),
    _Turma(nome: '11ª Classe A', disciplina: 'Física',     alunos: 24, sala: 'Sala 8',  pendentes: 1),
    _Turma(nome: '11ª Classe B', disciplina: 'Física',     alunos: 22, sala: 'Sala 3',  pendentes: 2),
    _Turma(nome: '12ª Classe A', disciplina: 'Matemática', alunos: 20, sala: 'Sala 5',  pendentes: 0),
    _Turma(nome: '12ª Classe B', disciplina: 'Física',     alunos: 18, sala: 'Sala 9',  pendentes: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: 0, right: 0,
            child: CustomPaint(size: const Size(160, 160), painter: _BlobPainter()),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Turmas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _navy)),
                          SizedBox(height: 2),
                          Text('As suas turmas activas', style: TextStyle(fontSize: 13, color: _grey)),
                        ],
                      ),
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.filter_list_rounded, color: _green, size: 22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: _turmas.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _TurmaCard(
                      turma: _turmas[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.classDetailTeacher,
                      ),
                    ),
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

class _TurmaCard extends StatelessWidget {
  const _TurmaCard({required this.turma, required this.onTap});

  final _Turma turma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPendentes = turma.pendentes > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, color: _green, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(turma.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navy)),
                  const SizedBox(height: 3),
                  Text('${turma.disciplina} · ${turma.sala}', style: const TextStyle(fontSize: 13, color: _grey)),
                  const SizedBox(height: 3),
                  Text('${turma.alunos} alunos', style: const TextStyle(fontSize: 12, color: _grey)),
                ],
              ),
            ),
            if (hasPendentes)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${turma.pendentes} pend.',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E0), size: 22),
          ],
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00B87A).withValues(alpha: 0.06);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.2, 0)
      ..cubicTo(0, 0, 0, size.height * 0.3, size.width * 0.1, size.height * 0.6)
      ..cubicTo(size.width * 0.2, size.height, size.width * 0.7, size.height, size.width, size.height * 0.7)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Turma {
  const _Turma({required this.nome, required this.disciplina, required this.alunos, required this.sala, required this.pendentes});
  final String nome, disciplina, sala;
  final int alunos, pendentes;
}
