import 'package:flutter/material.dart';
import 'grade_entry_students_screen.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class GradeEntryClassScreen extends StatefulWidget {
  const GradeEntryClassScreen({super.key, this.showBottomNav = false});

  final bool showBottomNav;

  @override
  State<GradeEntryClassScreen> createState() => _GradeEntryClassScreenState();
}

class Turma {
  const Turma({required this.nome, required this.disciplina, required this.alunos});

  final String nome;
  final String disciplina;
  final int alunos;
}

class _GradeEntryClassScreenState extends State<GradeEntryClassScreen> {
  Turma? _selecionada;

  static const _turmas = [
    Turma(nome: '10ª Classe A', disciplina: 'Matemática', alunos: 28),
    Turma(nome: '10ª Classe B', disciplina: 'Matemática', alunos: 26),
    Turma(nome: '11ª Classe A', disciplina: 'Física', alunos: 24),
    Turma(nome: '11ª Classe B', disciplina: 'Física', alunos: 22),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.showBottomNav,
        leading: widget.showBottomNav
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Lançar Notas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 28),
              const Text(
                'Selecione a Turma',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 4),
              const Text(
                'Passo 1 de 3',
                style: TextStyle(fontSize: 13, color: _grey),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: _turmas.map((t) => _TurmaCard(
                        turma: t,
                        selecionada: _selecionada == t,
                        onTap: () => setState(() => _selecionada = t),
                      )).toList(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selecionada == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GradeEntryStudentsScreen(turma: _selecionada!),
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFFE5E5EA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Próximo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _StepCircle(numero: '1', label: 'Turma', ativo: true),
        Expanded(
          child: Container(height: 2, color: const Color(0xFFE5E5EA)),
        ),
        _StepCircle(numero: '2', label: 'Avaliação', ativo: false),
        Expanded(
          child: Container(height: 2, color: const Color(0xFFE5E5EA)),
        ),
        _StepCircle(numero: '3', label: 'Notas', ativo: false),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.numero, required this.label, required this.ativo});

  final String numero;
  final String label;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: ativo ? _green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: ativo ? _green : const Color(0xFFE5E5EA)),
          ),
          child: Center(
            child: Text(
              numero,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ativo ? Colors.white : _grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: ativo ? _green : _grey, fontWeight: ativo ? FontWeight.w600 : FontWeight.normal),
        ),
      ],
    );
  }
}

class _TurmaCard extends StatelessWidget {
  const _TurmaCard({required this.turma, required this.selecionada, required this.onTap});

  final Turma turma;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: selecionada ? Border.all(color: _green, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  turma.nome,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _green),
                ),
                const SizedBox(height: 8),
                Text(
                  turma.disciplina,
                  style: const TextStyle(fontSize: 13, color: _grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${turma.alunos} alunos',
                  style: const TextStyle(fontSize: 12, color: _grey),
                ),
              ],
            ),
            if (selecionada)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.check_circle_rounded, color: _green, size: 24),
              ),
          ],
        ),
      ),
    );
  }
}


