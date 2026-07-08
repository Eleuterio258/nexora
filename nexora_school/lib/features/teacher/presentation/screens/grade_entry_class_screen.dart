import 'package:flutter/material.dart';
import 'package:nexora_school/core/constants/app_routes.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class GradeEntryClassScreen extends StatelessWidget {
  const GradeEntryClassScreen({super.key, this.showBottomNav = false});

  final bool showBottomNav;

  static const _turmas = [
    _Turma(
      nome: '10ª Classe A',
      disciplina: 'Matemática',
      pendentes: 3,
      total: 28,
    ),
    _Turma(
      nome: '10ª Classe B',
      disciplina: 'Matemática',
      pendentes: 0,
      total: 26,
    ),
    _Turma(nome: '11ª Classe A', disciplina: 'Física', pendentes: 1, total: 24),
    _Turma(nome: '11ª Classe B', disciplina: 'Física', pendentes: 2, total: 22),
    _Turma(
      nome: '12ª Classe A',
      disciplina: 'Matemática',
      pendentes: 0,
      total: 20,
    ),
    _Turma(nome: '12ª Classe B', disciplina: 'Física', pendentes: 0, total: 18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Notas',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Seleccione uma turma para lançar notas',
                        style: TextStyle(fontSize: 13, color: _grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: _turmas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) => _GradeTurmaCard(
                      turma: _turmas[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.gradeEntryStudents,
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

class _GradeTurmaCard extends StatelessWidget {
  const _GradeTurmaCard({required this.turma, required this.onTap});

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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasPendentes
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.10)
                    : _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.grade_rounded,
                color: hasPendentes ? const Color(0xFFF59E0B) : _green,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turma.nome,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    turma.disciplina,
                    style: const TextStyle(fontSize: 13, color: _grey),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: hasPendentes
                          ? (turma.total - turma.pendentes) / turma.total
                          : 1.0,
                      backgroundColor: const Color(0xFFEEEEF0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasPendentes ? const Color(0xFFF59E0B) : _green,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPendentes
                        ? '${turma.pendentes} notas por lançar'
                        : 'Todas as notas lançadas',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasPendentes ? const Color(0xFFF59E0B) : _green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E0),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

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

class _Turma {
  const _Turma({
    required this.nome,
    required this.disciplina,
    required this.pendentes,
    required this.total,
  });
  final String nome, disciplina;
  final int pendentes, total;
}
