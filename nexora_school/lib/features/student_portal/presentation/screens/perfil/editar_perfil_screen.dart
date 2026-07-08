import 'package:flutter/material.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../../domain/repositories/student_portal_repository.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _enderecoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await sl<StudentPortalRepository>().atualizarPerfil(
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        telefone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        endereco:
            _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado com sucesso'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao actualizar perfil'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
              _buildField(
                label: 'Email',
                ctrl: _emailCtrl,
                icon: Icons.email_outlined,
                hint: 'Novo email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Telefone',
                ctrl: _telCtrl,
                icon: Icons.phone_outlined,
                hint: '+258 84 000 0000',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Endereço',
                ctrl: _enderecoCtrl,
                icon: Icons.location_on_outlined,
                hint: 'Ex: Av. Eduardo Mondlane, Maputo',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF8E8E93), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Preencha apenas os campos que pretende actualizar. Campos em branco mantêm o valor actual.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Guardar alterações',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
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
          bottom: 0,
          right: 0,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: _navy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
            prefixIcon: Icon(icon, color: _green, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
}
