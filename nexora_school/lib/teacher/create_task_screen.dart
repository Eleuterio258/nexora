import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  String _categoria = 'TPC';
  final Set<String> _turmas = {'Turma 10ª A'};
  DateTime _dataEntrega = DateTime(2026, 6, 25);
  final _notaMaxController = TextEditingController(text: '20');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nova Tarefa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _publicar,
            child: const Text(
              'Publicar',
              style: TextStyle(color: _green, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(label: 'Título da Tarefa'),
              const SizedBox(height: 16),
              _buildTextArea(label: 'Descrição e Instruções'),
              const SizedBox(height: 16),
              _buildDropdown(label: 'Disciplina', valor: 'Matemática'),
              const SizedBox(height: 16),
              _buildTurmas(),
              const SizedBox(height: 16),
              _buildDataEntrega(),
              const SizedBox(height: 16),
              _buildNotaMax(),
              const SizedBox(height: 16),
              _buildCategorias(),
              const SizedBox(height: 24),
              _buildAnexos(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined, color: _green, size: 18),
                label: const Text('Ver como Aluno', style: TextStyle(color: _green)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0FDF4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0FDF4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String valor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: valor,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _grey),
              items: const [
                DropdownMenuItem(value: 'Matemática', child: Text('Matemática')),
                DropdownMenuItem(value: 'Física', child: Text('Física')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTurmas() {
    final turmas = ['Turma 10ª A', 'Turma 10ª B', 'Turma 11ª A', 'Turma 11ª B'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Turma(s)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: turmas.map((t) {
            final selecionada = _turmas.contains(t);
            return FilterChip(
              selected: selecionada,
              onSelected: (sel) => setState(() => sel ? _turmas.add(t) : _turmas.remove(t)),
              label: Text(t),
              selectedColor: const Color(0xFFF0FDF4),
              checkmarkColor: _green,
              labelStyle: TextStyle(color: selecionada ? _green : _navy, fontWeight: FontWeight.w600),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selecionada ? _green : const Color(0xFFE5E5EA))),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataEntrega() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Data de Entrega', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final data = await showDatePicker(
              context: context,
              initialDate: _dataEntrega,
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
            );
            if (data != null) setState(() => _dataEntrega = data);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: _green),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_dataEntrega.day.toString().padLeft(2, '0')}/${_dataEntrega.month.toString().padLeft(2, '0')}/${_dataEntrega.year}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy),
                    ),
                    const Text('23h59', style: TextStyle(fontSize: 12, color: _grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotaMax() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nota Máxima', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        TextField(
          controller: _notaMaxController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0FDF4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: '0-20 valores',
            hintStyle: const TextStyle(color: _grey),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorias() {
    final categorias = ['TPC', 'Ficha', 'Projeto', 'Oral'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categorias.map((c) {
            final selecionada = _categoria == c;
            return ChoiceChip(
              selected: selecionada,
              onSelected: (_) => setState(() => _categoria = c),
              label: Text(c),
              selectedColor: _green,
              labelStyle: TextStyle(color: selecionada ? Colors.white : _navy, fontWeight: FontWeight.w600),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selecionada ? _green : const Color(0xFFE5E5EA))),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnexos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Anexar Recursos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        Row(
          children: [
            _AnexoButton(icon: Icons.camera_alt_outlined, label: 'Câmara'),
            const SizedBox(width: 10),
            _AnexoButton(icon: Icons.attach_file_rounded, label: 'Ficheiro'),
            const SizedBox(width: 10),
            _AnexoButton(icon: Icons.link_rounded, label: 'Link'),
          ],
        ),
      ],
    );
  }

  void _publicar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tarefa publicada com sucesso'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _AnexoButton extends StatelessWidget {
  const _AnexoButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: _green, size: 18),
      label: Text(label, style: const TextStyle(color: _green, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
