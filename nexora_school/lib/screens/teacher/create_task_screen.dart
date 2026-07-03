import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy  = Color(0xFF0D1B2A);

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _tituloCtrl    = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  String _turma = '10ª Classe A';
  DateTime _prazo = DateTime.now().add(const Duration(days: 7));

  static const _turmas = ['10ª Classe A', '10ª Classe B', '11ª Classe A', '11ª Classe B', '12ª Classe A', '12ª Classe B'];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _prazo,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _prazo = picked);
  }

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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
                  ),
                  const SizedBox(width: 12),
                  const Text('Nova Tarefa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navy)),
                ],
              ),
              const SizedBox(height: 28),
              _Label('Título da Tarefa'),
              const SizedBox(height: 8),
              TextField(
                controller: _tituloCtrl,
                decoration: _inputDecoration('Ex: Exercícios de álgebra'),
              ),
              const SizedBox(height: 20),
              _Label('Turma'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _turma,
                    isExpanded: true,
                    items: _turmas.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _turma = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _Label('Prazo de Entrega'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: _green, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${_prazo.day.toString().padLeft(2, '0')}/${_prazo.month.toString().padLeft(2, '0')}/${_prazo.year}',
                        style: const TextStyle(fontSize: 14, color: _navy),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _Label('Descrição'),
              const SizedBox(height: 8),
              TextField(
                controller: _descricaoCtrl,
                maxLines: 5,
                decoration: _inputDecoration('Descreva a tarefa em detalhe...'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Publicar Tarefa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDC7), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy));
  }
}
