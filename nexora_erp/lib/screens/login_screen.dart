import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../services/auth_service.dart';
import '../theme/nexora_colors.dart';
import 'home_screen.dart';

/// Réplica 1:1 (cores, textos, estrutura e comportamento) do
/// `auth_activity_login.xml` + `LoginActivity.kt` do nexora_assiduidade.
/// Inclui deliberadamente os erros de escrita/typos do original
/// ("ASSEDUIDADE", falta de acentos em algumas mensagens).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogin() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Preencha todos os campos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(username, password);
      if (!mounted) return;
      _showMessage('Login realizado com sucesso.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: result.user)),
      );
    } on AuthException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillDemo(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: NexoraColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: NexoraColors.surfaceBg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: _buildFormCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      color: NexoraColors.loginHeroBg,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: NexoraColors.badgeFill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: NexoraColors.badgeStroke),
            ),
            child: const Text(
              'NEXORA ASSEDUIDADE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Assiduidade inteligente para equipas modernas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'O mesmo padrao visual do portal web, adaptado para mobile.',
            style: TextStyle(
              color: NexoraColors.heroSubtitle,
              fontSize: 14,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _featureChip(Icons.camera_alt, 'Facial'),
              const SizedBox(width: 10),
              _featureChip(Icons.location_on, 'GPS'),
              const SizedBox(width: 10),
              _featureChip(Icons.nfc, 'NFC'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: NexoraColors.featureFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NexoraColors.featureStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: const BoxDecoration(
        color: NexoraColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entrar',
            style: TextStyle(
              color: NexoraColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Acesse a sua conta para continuar',
            style: TextStyle(color: NexoraColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 22),
          _fieldLabel('Utilizador'),
          const SizedBox(height: 8),
          _inputRow(
            icon: Icons.person_outline,
            controller: _emailController,
            hint: 'Codigo do funcionario ou email',
            obscure: false,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Senha'),
          const SizedBox(height: 8),
          _inputRow(
            icon: Icons.lock_outline,
            controller: _passwordController,
            hint: 'Senha',
            obscure: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: NexoraColors.textMuted,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: NexoraColors.brandAccent,
                disabledBackgroundColor: NexoraColors.brandAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isLoading ? 'A autenticar...' : 'Entrar',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 14),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: NexoraColors.border)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'ACESSO RAPIDO',
                  style: TextStyle(
                    color: NexoraColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: NexoraColors.border)),
            ],
          ),
          const SizedBox(height: 14),
          if (kDebugMode) ...[
            _demoButton(
              icon: Icons.person_outline,
              iconTint: NexoraColors.brandAccent,
              title: 'Funcionario',
              subtitle: DemoCredentials.funcionarioLabelSubtitle,
              onTap: () => _fillDemo(
                DemoCredentials.funcionarioEmail,
                DemoCredentials.funcionarioPassword,
              ),
            ),
            const SizedBox(height: 10),
            _demoButton(
              icon: Icons.manage_accounts,
              iconTint: NexoraColors.green,
              title: 'Gestor',
              subtitle: DemoCredentials.gestorLabelSubtitle,
              onTap: () => _fillDemo(
                DemoCredentials.gestorEmail,
                DemoCredentials.gestorPassword,
              ),
            ),
            const SizedBox(height: 18),
          ],
          const Center(
            child: Text(
              'Esqueceu a senha?',
              style: TextStyle(
                color: NexoraColors.brandAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: NexoraColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _inputRow({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    Widget? suffix,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: NexoraColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NexoraColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: NexoraColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(
                color: NexoraColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: hint,
                hintStyle: const TextStyle(color: NexoraColors.textMuted),
              ),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }

  Widget _demoButton({
    required IconData icon,
    required Color iconTint,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NexoraColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NexoraColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NexoraColors.greenDim,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: iconTint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: NexoraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: NexoraColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
