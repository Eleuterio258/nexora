import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:nexora_school/core/constants/app_routes.dart';
import 'package:nexora_school/core/local/local_storage/i_local_storage.dart';
import 'package:nexora_school/features/student_portal/domain/entities/student_home_data.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_home_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_home_state.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/perfil/editar_perfil_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/perfil/seguranca_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/perfil/notificacoes_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/perfil/ajuda_faq_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/frequencia/frequencia_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/frequencia/faltas_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/ocorrencias/ocorrencias_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/biblioteca/biblioteca_screen.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);

class PerfilTab extends StatelessWidget {
  const PerfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Blob decorativo canto superior direito
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(160, 160),
              painter: _BlobPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: BlocBuilder<StudentHomeCubit, StudentHomeState>(
                    builder: (context, state) {
                      return switch (state) {
                        StudentHomeLoading() => const Center(
                          child: CircularProgressIndicator(color: _green),
                        ),
                        StudentHomeError(:final message) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Erro ao carregar dados: $message',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        StudentHomeLoaded(:final data) => _buildBody(
                          context,
                          data,
                        ),
                        _ => const SizedBox.shrink(),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, StudentHomeData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildProfileCard(data),
          const SizedBox(height: 24),
          _buildSection('Conta', [
            _MenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Editar perfil',
              subtitle: 'Actualize as suas informações pessoais',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
              ),
            ),
            _MenuItem(
              icon: Icons.lock_outline_rounded,
              title: 'Segurança',
              subtitle: 'Altere a sua senha e configurações',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SegurancaScreen()),
              ),
            ),
            _MenuItem(
              icon: Icons.how_to_reg_outlined,
              title: 'Frequência',
              subtitle: 'Veja a sua assiduidade por disciplina',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FrequenciaScreen()),
              ),
            ),
            _MenuItem(
              icon: Icons.cancel_outlined,
              title: 'Justificar faltas',
              subtitle: 'Envie pedidos de justificação de faltas',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaltasScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Escola', [
            _MenuItem(
              icon: Icons.report_outlined,
              title: 'Ocorrências',
              subtitle: 'Incidentes, sanções e méritos registados',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OcorrenciasScreen()),
              ),
            ),
            _MenuItem(
              icon: Icons.menu_book_outlined,
              title: 'Biblioteca',
              subtitle: 'Histórico de empréstimos de livros',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BibliotecaScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Preferências', [
            _MenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notificações',
              subtitle: 'Escolha como deseja receber avisos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
              ),
            ),
            _MenuItem(
              icon: Icons.palette_outlined,
              title: 'Aparência',
              subtitle: 'Personalize o tema da aplicação',
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Suporte', [
            _MenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Ajuda e FAQ',
              subtitle: 'Tire as suas dúvidas',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AjudaFaqScreen()),
              ),
            ),
            _MenuItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Fale connosco',
              subtitle: 'Entre em contacto com a nossa equipa',
            ),
          ]),
          const SizedBox(height: 24),
          _buildLogoutBtn(context),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Gerencie suas informações e preferências',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, size: 28, color: _navy),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card do perfil ────────────────────────────────────────────────────────

  Widget _buildProfileCard(StudentHomeData data) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _green,
                    size: 40,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.nome,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Aluno',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.turma,
                    style: const TextStyle(fontSize: 13, color: _navy),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.anoLectivo,
                    style: const TextStyle(fontSize: 13, color: _navy),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_outlined, color: _green, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFF0F2F5)),
        const SizedBox(height: 12),
        Row(
          children: [
            _InfoChip(
              icon: Icons.email_outlined,
              label: 'E-mail',
              value: data.email,
            ),
            _InfoChip(
              icon: Icons.badge_outlined,
              label: 'Matrícula',
              value: data.matricula,
            ),
            _InfoChip(
              icon: Icons.calendar_today_outlined,
              label: 'Ingresso',
              value: _formatDate(data.dataIngresso),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  // ── Secção com itens ──────────────────────────────────────────────────────

  Widget _buildSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return _buildMenuItem(entry.value, isLast: isLast);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item, {required bool isLast}) {
    return Column(
      children: [
        InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(item.icon, color: _green, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E0),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: Color(0xFFF0F2F5),
          ),
      ],
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Widget _buildLogoutBtn(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await GetIt.instance<ILocalStorage>().clear();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Sair da conta'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ── Chip de info ───────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _green),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Blob painter ───────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00B87A).withValues(alpha: 0.06);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.2, 0)
      ..cubicTo(0, 0, 0, size.height * 0.3, size.width * 0.1, size.height * 0.6)
      ..cubicTo(
        size.width * 0.2,
        size.height,
        size.width * 0.7,
        size.height,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}
