import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class GradeEntryStudentsScreen extends StatefulWidget {
  const GradeEntryStudentsScreen({super.key});

  @override
  State<GradeEntryStudentsScreen> createState() =>
      _GradeEntryStudentsScreenState();
}

class _GradeEntryStudentsScreenState extends State<GradeEntryStudentsScreen> {
  static const _alunos = [
    'Ana Beatriz Silva',
    'Bruno Machava',
    'Carlos Nhaca',
    'Diana Tembe',
    'Eduardo Sitoe',
    'Fátima Cumbe',
    'Gilberto Macuácua',
    'Helena Nguenha',
    'Ivo Cossa',
    'Joana Matsimbe',
    'Kevin Bila',
    'Lúcia Chissano',
  ];

  late final List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(_alunos.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lançar Notas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                      Text(
                        'Matemática · 10ª A · Teste 2',
                        style: TextStyle(fontSize: 12, color: _grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: _alunos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) =>
                    _NotaTile(nome: _alunos[i], numero: i + 1, ctrl: _ctrls[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Guardar Notas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotaTile extends StatelessWidget {
  const _NotaTile({
    required this.nome,
    required this.numero,
    required this.ctrl,
  });

  final String nome;
  final int numero;
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$numero',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _green,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nome,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _navy,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
              decoration: InputDecoration(
                hintText: '0–20',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFCCCCCC),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _green, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
