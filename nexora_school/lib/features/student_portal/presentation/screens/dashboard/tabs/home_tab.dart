import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/features/student_portal/domain/entities/student_home_data.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_home_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_home_state.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/dashboard/sub/noticias_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/dashboard/sub/calendario_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/dashboard/sub/turma_screen.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/dashboard/sub/notificacoes_screen.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(160, 160),
              painter: _BlobPainter(),
            ),
          ),
          SafeArea(
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
                  StudentHomeLoaded(:final data) => _buildContent(
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
    );
  }

  Widget _buildContent(BuildContext context, StudentHomeData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, data.nome),
          const SizedBox(height: 24),
          _buildResumoCard(data),
          const SizedBox(height: 24),
          _buildQuickAccess(context),
          const SizedBox(height: 28),
          _buildStats(data),
          const SizedBox(height: 28),
          _buildCompromissos(data.eventos),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String nome) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Início',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bem-vindo, $nome',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: _navy,
                  size: 22,
                ),
              ),
              Positioned(
                top: 8,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Resumo card ───────────────────────────────────────────────────────────

  Widget _buildResumoCard(StudentHomeData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A36C), Color(0xFF00C98A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HOJE',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${data.aulasHoje} Aulas',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 56, color: Colors.white24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MÉDIA',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              data.mediaGeral.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data.turma} · ${data.anoLectivo}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Acesso rápido ─────────────────────────────────────────────────────────

  Widget _buildQuickAccess(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickCard(
            icon: Icons.newspaper_outlined,
            label: 'Notícias',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoticiasScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickCard(
            icon: Icons.calendar_month_outlined,
            label: 'Calendário',
            color: const Color(0xFFE65100),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarioScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickCard(
            icon: Icons.groups_outlined,
            label: 'Turma',
            color: const Color(0xFF6750A4),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TurmaScreen()),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStats(StudentHomeData data) {
    const divider = Color(0xFFEEEEF0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumo Académico',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.school_rounded,
                iconColor: const Color(0xFF00B87A),
                value: '${data.faltas}',
                valueColor: const Color(0xFF00B87A),
                label: 'Faltas',
                sub: 'de ${data.faltasPermitidas} permitidas',
              ),
            ),
            Container(width: 1, height: 72, color: divider),
            Expanded(
              child: _StatItem(
                icon: Icons.assignment_rounded,
                iconColor: const Color(0xFF6B4EFF),
                value: data.mediaGeral.toStringAsFixed(1),
                valueColor: const Color(0xFF6B4EFF),
                label: 'Média Geral',
                sub: 'Excelente!',
              ),
            ),
          ],
        ),
        const Divider(height: 1, color: divider),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF3B82F6),
                value: '${data.mensagens.length}',
                valueColor: const Color(0xFF3B82F6),
                label: 'Avisos',
                sub: 'não lidos',
              ),
            ),
            Container(width: 1, height: 72, color: divider),
            Expanded(
              child: _StatItem(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: '${data.eventos.length}',
                valueColor: const Color(0xFFF59E0B),
                label: 'Eventos',
                sub: 'próximos',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Compromissos ──────────────────────────────────────────────────────────

  Widget _buildCompromissos(List<dynamic> eventos) {
    final compromissos = eventos.take(5).map((e) {
      final titulo = (e['titulo'] ?? 'Evento').toString();
      final data = (e['data_inicio'] ?? e['data'] ?? '').toString();
      final hora = (e['hora_inicio'] ?? e['hora'] ?? '').toString();
      final categoria = (e['categoria'] ?? 'Evento').toString();
      final cor = _parseColor(e['cor']);
      return _Compromisso(
        titulo: titulo,
        date: data.isNotEmpty ? data : '--/--/----',
        time: hora.isNotEmpty ? hora : '--:--',
        badge: categoria,
        badgeColor: cor,
        icon: Icons.event_note_outlined,
        color: cor,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximos Compromissos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 18, color: _green),
                SizedBox(width: 4),
                Text(
                  'Ver tudo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (compromissos.isEmpty)
          const Text(
            'Sem compromissos próximos.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          )
        else
          ...compromissos.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CompromissoCard(item: c),
            ),
          ),
      ],
    );
  }

  static Color _parseColor(dynamic value) {
    if (value == null) return _green;
    final hex = value.toString().replaceFirst('#', '');
    final color = int.tryParse(hex, radix: 16);
    if (color == null) return _green;
    return Color(0xFF000000 + color);
  }
}

// ── Quick access card ──────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    required this.sub,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompromissoCard extends StatelessWidget {
  const _CompromissoCard({required this.item});
  final _Compromisso item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.date}  ·  ${item.time}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.badge,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: item.badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blob ───────────────────────────────────────────────────────────────────────

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

// ── Data ───────────────────────────────────────────────────────────────────────

class _Compromisso {
  const _Compromisso({
    required this.titulo,
    required this.date,
    required this.time,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.color,
  });
  final String titulo, date, time, badge;
  final Color badgeColor, color;
  final IconData icon;
}
