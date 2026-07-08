import 'package:flutter/material.dart';
import 'package:nexora_school/core/di/injection.dart';
import '../../../data/datasources/student_portal_remote_datasource.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);

class SegurancaScreen extends StatefulWidget {
  const SegurancaScreen({super.key});

  @override
  State<SegurancaScreen> createState() => _SegurancaScreenState();
}

class _SegurancaScreenState extends State<SegurancaScreen> {
  bool _showAtual = false;
  bool _showNova = false;
  bool _showConf = false;
  bool _loading = false;

  final _atualCtrl = TextEditingController();
  final _novaCtrl = TextEditingController();
  final _confCtrl = TextEditingController();

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _alterar() async {
    final atual = _atualCtrl.text.trim();
    final nova = _novaCtrl.text.trim();
    final conf = _confCtrl.text.trim();

    if (atual.isEmpty || nova.isEmpty || conf.isEmpty) {
      _showSnack('Preencha todos os campos', isError: true);
      return;
    }
    if (nova.length < 8) {
      _showSnack('A nova senha deve ter pelo menos 8 caracteres', isError: true);
      return;
    }
    if (nova != conf) {
      _showSnack('As senhas não coincidem', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await sl<StudentPortalRemoteDatasource>().alterarSenha(
        senhaActual: atual,
        novaSenha: nova,
      );
      if (mounted) {
        _showSnack('Senha alterada com sucesso');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) _showSnack('Erro ao alterar senha', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        title: const Text('Segurança',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildInfoCard(),
            const SizedBox(height: 28),
            const Text('Alterar senha',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _navy)),
            const SizedBox(height: 16),
            _buildPassField(
              label: 'Senha actual',
              ctrl: _atualCtrl,
              visible: _showAtual,
              onToggle: () => setState(() => _showAtual = !_showAtual),
            ),
            const SizedBox(height: 16),
            _buildPassField(
              label: 'Nova senha',
              ctrl: _novaCtrl,
              visible: _showNova,
              onToggle: () => setState(() => _showNova = !_showNova),
            ),
            const SizedBox(height: 16),
            _buildPassField(
              label: 'Confirmar nova senha',
              ctrl: _confCtrl,
              visible: _showConf,
              onToggle: () => setState(() => _showConf = !_showConf),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _alterar,
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
                    : const Text('Actualizar senha',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: _green, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Use uma senha com pelo menos 8 caracteres, incluindo letras e números.',
              style: TextStyle(fontSize: 13, color: _green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassField({
    required String label,
    required TextEditingController ctrl,
    required bool visible,
    required VoidCallback onToggle,
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
          obscureText: !visible,
          style: const TextStyle(fontSize: 14, color: _navy),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: _green, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF8E8E93),
                size: 20,
              ),
              onPressed: onToggle,
            ),
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
