import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/applications/domain/entities/application.dart';
import '../features/applications/presentation/bloc/application_bloc.dart';
import '../widgets/nexora_logo.dart';
import 'application_detail_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

// ApplicationBloc é fornecido globalmente em app.dart (MultiBlocProvider) —
// o carregamento inicial é despoletado em main_screen.dart.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ApplicationsView();
}

class _ApplicationsView extends StatefulWidget {
  const _ApplicationsView();

  @override
  State<_ApplicationsView> createState() => _ApplicationsViewState();
}

class _ApplicationsViewState extends State<_ApplicationsView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Green header
            Stack(
              children: [
                const Positioned.fill(child: GreenHeaderDecoration()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              NexoraLogoIcon(size: 26, isWhite: true),
                              SizedBox(width: 8),
                              Text(
                                'Nexora',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsScreen()),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Minhas Candidaturas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Acompanhe as suas candidaturas e o respectivo estado',
                        style: TextStyle(color: Colors.white70, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Body
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(
                              Icons.search,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (v) =>
                                    setState(() => _query = v.trim().toLowerCase()),
                                decoration: InputDecoration(
                                  hintText: 'Pesquisar candidaturas',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Application list
                    Expanded(
                      child: BlocBuilder<ApplicationBloc, ApplicationState>(
                        builder: (context, state) {
                          if (state is ApplicationLoading ||
                              state is ApplicationInitial) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (state is ApplicationFailureState) {
                            return Center(
                              child: Text(state.message,
                                  style: TextStyle(color: Colors.grey.shade600)),
                            );
                          }
                          final apps =
                              state is ApplicationsLoaded ? state.applications : <Application>[];
                          final filtered = _query.isEmpty
                              ? apps
                              : apps
                                  .where((a) =>
                                      a.jobTitle.toLowerCase().contains(_query))
                                  .toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Text(
                                'Ainda não submeteu nenhuma candidatura.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ApplicationDetailScreen(
                                    application: filtered[i],
                                  ),
                                ),
                              ),
                              child: _ApplicationCard(app: filtered[i]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Application app;
  const _ApplicationCard({required this.app});

  Color get _statusColor {
    switch (app.status) {
      case ApplicationStatus.interview:
        return const Color(0xFFE57C00);
      case ApplicationStatus.inReview:
        return const Color(0xFF4A90D9);
      case ApplicationStatus.rejected:
        return const Color(0xFFB00020);
      default:
        return kPrimary;
    }
  }

  Color get _statusBg {
    switch (app.status) {
      case ApplicationStatus.interview:
        return const Color(0xFFFFF3E8);
      case ApplicationStatus.inReview:
        return const Color(0xFFEBF3FF);
      case ApplicationStatus.rejected:
        return const Color(0xFFFBE9E7);
      default:
        return const Color(0xFFE8F8F0);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2E2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: NexoraLogoIcon(size: 26, isWhite: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.jobTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: Color(0xFF1A2E2A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        app.company,
                        style: const TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (app.trackingCode != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Código: ${app.trackingCode}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF2F2F2)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 5),
                Text(
                  _fmt(app.appliedAt),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    app.status.pt,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF2F2F2)),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.chat_bubble_outline,
              label: 'Contactar Recrutador',
              color: kPrimary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    candidaturaId: app.id,
                    name: app.jobTitle,
                    role: app.status.pt,
                    company: app.company,
                    avatarColor: const Color(0xFF1A2E2A),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
