import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy  = Color(0xFF0D1B2A);

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl     = TextEditingController(text: 'Manuel Cossa');
  final _emailCtrl    = TextEditingController(text: 'manuel.cossa@e258.com');
  final _telCtrl      = TextEditingController(text: '+258 84 000 0000');
  final _nascCtrl     = TextEditingController(text: '12/05/2009');

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _nascCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editar Perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildAvatar(),
              const SizedBox(height: 32),
              _buildField(label: 'Nome completo', ctrl: _nomeCtrl, icon: Icons.person_outline_rounded),
              const SizedBox(height: 16),
              _buildField(label: 'Email', ctrl: _emailCtrl, icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField(label: 'Telefone', ctrl: _telCtrl, icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField(label: 'Data de nascimento', ctrl: _nascCtrl,
                  icon: Icons.calendar_today_outlined, readOnly: true),
              const SizedBox(height: 32),
              _buildSaveBtn(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: _green, size: 44),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 14, color: _navy),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _green, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveBtn(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado com sucesso'),
              backgroundColor: _green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Text('Guardar alterações',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
