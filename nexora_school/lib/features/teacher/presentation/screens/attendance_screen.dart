import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
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

  final Map<int, bool> _presencas = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _alunos.length; i++) {
      _presencas[i] = true;
    }
  }

  int get _presentes => _presencas.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marcar Presenças',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                        Text(
                          'Matemática · 10ª A · 08h00',
                          style: TextStyle(fontSize: 12, color: _grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A36C), Color(0xFF00C98A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatPill(
                      label: 'Presentes',
                      value: '$_presentes',
                      color: Colors.white,
                    ),
                    Container(width: 1, height: 32, color: Colors.white24),
                    _StatPill(
                      label: 'Ausentes',
                      value: '${_alunos.length - _presentes}',
                      color: Colors.white,
                    ),
                    Container(width: 1, height: 32, color: Colors.white24),
                    _StatPill(
                      label: 'Total',
                      value: '${_alunos.length}',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: _alunos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _AlunoPresencaTile(
                  nome: _alunos[i],
                  numero: i + 1,
                  presente: _presencas[i] ?? true,
                  onChanged: (v) => setState(() => _presencas[i] = v),
                ),
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
                    'Guardar Presenças',
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

class _AlunoPresencaTile extends StatelessWidget {
  const _AlunoPresencaTile({
    required this.nome,
    required this.numero,
    required this.presente,
    required this.onChanged,
  });

  final String nome;
  final int numero;
  final bool presente;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: presente
                  ? _green.withValues(alpha: 0.08)
                  : Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$numero',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: presente ? _green : Colors.red,
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
          Row(
            children: [
              GestureDetector(
                onTap: () => onChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: presente ? _green : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: presente ? _green : const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: Text(
                    'P',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: presente ? Colors.white : _grey,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: !presente ? Colors.red : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: !presente ? Colors.red : const Color(0xFFE5E5EA),
                    ),
                  ),
                  child: Text(
                    'F',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: !presente ? Colors.white : _grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}
