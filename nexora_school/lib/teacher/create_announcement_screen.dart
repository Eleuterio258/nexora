import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _grey = Color(0xFF8E8E93);

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final Set<String> _destinatarios = {'10ª Classe A'};
  bool _urgente = false;
  String _categoria = 'Informativo';
  bool _agendar = false;

  final _destinatariosOpcoes = [
    '10ª Classe A',
    '10ª Classe B',
    '11ª Classe A',
    '11ª Classe B',
    'Todos os Alunos',
    'Todos os Encarregados',
  ];

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
          'Novo Comunicado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _enviar,
            child: const Text(
              'Enviar',
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
              const Text(
                'Enviar para:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _destinatariosOpcoes.map((d) {
                  final selecionado = _destinatarios.contains(d);
                  return FilterChip(
                    selected: selecionado,
                    onSelected: (sel) => setState(() => sel ? _destinatarios.add(d) : _destinatarios.remove(d)),
                    label: Text(d),
                    selectedColor: const Color(0xFFF0FDF4),
                    checkmarkColor: _green,
                    labelStyle: TextStyle(color: selecionado ? _green : _navy, fontWeight: FontWeight.w600),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: selecionado ? _green : const Color(0xFFE5E5EA)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Marcar como Urgente',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy),
                    ),
                    Switch(
                      value: _urgente,
                      onChanged: (v) => setState(() => _urgente = v),
                      activeTrackColor: _green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDropdown(label: 'Categoria', valor: _categoria),
              const SizedBox(height: 16),
              _buildTextField(label: 'Título'),
              const SizedBox(height: 16),
              _buildTextArea(label: 'Mensagem'),
              const SizedBox(height: 16),
              _buildAgendamento(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.attach_file_rounded, color: _green, size: 18),
                label: const Text('Anexar ficheiro', style: TextStyle(color: _green)),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Será enviado para ${_calcularDestinatarios()} destinatários',
                  style: const TextStyle(fontSize: 13, color: _grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calcularDestinatarios() {
    int total = 0;
    if (_destinatarios.contains('10ª Classe A')) total += 28;
    if (_destinatarios.contains('10ª Classe B')) total += 26;
    if (_destinatarios.contains('11ª Classe A')) total += 24;
    if (_destinatarios.contains('11ª Classe B')) total += 22;
    if (_destinatarios.contains('Todos os Alunos')) total = 142;
    if (_destinatarios.contains('Todos os Encarregados')) total = 142;
    return total;
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
                DropdownMenuItem(value: 'Informativo', child: Text('Informativo')),
                DropdownMenuItem(value: 'Aviso', child: Text('Aviso')),
                DropdownMenuItem(value: 'Evento', child: Text('Evento')),
                DropdownMenuItem(value: 'Lembrete', child: Text('Lembrete')),
              ],
              onChanged: (v) => setState(() => _categoria = v ?? 'Informativo'),
            ),
          ),
        ),
      ],
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
          maxLines: 5,
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

  Widget _buildAgendamento() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: _green),
              SizedBox(width: 10),
              Text(
                'Agendamento',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navy),
              ),
            ],
          ),
          _RadioOption(
            label: 'Enviar Agora',
            value: false,
            groupValue: _agendar,
            onChanged: (v) => setState(() => _agendar = v),
          ),
          _RadioOption(
            label: 'Agendar Envio',
            value: true,
            groupValue: _agendar,
            onChanged: (v) => setState(() => _agendar = v),
          ),
        ],
      ),
    );
  }

  void _enviar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comunicado enviado para ${_calcularDestinatarios()} destinatários'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool groupValue;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? _green : const Color(0xFFE5E5EA), width: 2),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: _navy),
            ),
          ],
        ),
      ),
    );
  }
}
