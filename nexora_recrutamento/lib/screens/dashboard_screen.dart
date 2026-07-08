import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/applications/domain/entities/application.dart';
import '../features/applications/presentation/bloc/application_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/jobs/presentation/bloc/job_bloc.dart';
import '../widgets/nexora_logo.dart';
import 'application_detail_screen.dart';
import 'notifications_screen.dart';

// ApplicationBloc é fornecido globalmente em app.dart (MultiBlocProvider) —
// o carregamento inicial é despoletado em main_screen.dart.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _DashboardView();
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  Color _statusColor(ApplicationStatus s) {
    switch (s) {
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  int _stepReached(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.inReview:
        return 1;
      case ApplicationStatus.interview:
        return 2;
      case ApplicationStatus.approved:
      case ApplicationStatus.rejected:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final nome = authState is AuthAuthenticated
        ? authState.user.nome.split(' ').first
        : 'candidato';
    final jobState = context.watch<JobBloc>().state;
    final jobDescriptions = jobState is JobsLoaded
        ? {
            for (final job in jobState.jobs)
              if (job.description.isNotEmpty) job.id: job.description,
          }
        : <int, String>{};

    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Green header ──
            Stack(
              children: [
                const Positioned.fill(child: GreenHeaderDecoration()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NexoraLogoIcon(size: 26, isWhite: true),
                          const SizedBox(width: 8),
                          const Text(
                            'NEXORA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                            child: Stack(
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF5252),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Olá, $nome! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Acompanhe as suas candidaturas e dê\no próximo passo na sua carreira.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── Body ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: BlocBuilder<ApplicationBloc, ApplicationState>(
                  builder: (context, state) {
                    if (state is ApplicationLoading ||
                        state is ApplicationInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ApplicationFailureState) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }
                    final apps = state is ApplicationsLoaded
                        ? state.applications
                        : <Application>[];

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Minhas Candidaturas',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A2E2A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (apps.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Ainda não submeteu nenhuma candidatura.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          else ...[
                            for (final app in apps.take(3)) ...[
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ApplicationDetailScreen(
                                      application: app,
                                    ),
                                  ),
                                ),
                                child: _AppCard(
                                  title: app.jobTitle,
                                  description:
                                      _descriptionFor(app, jobDescriptions),
                                  date: _fmt(app.appliedAt),
                                  status: app.status.pt,
                                  statusColor: _statusColor(app.status),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 12),
                            // ── Progress card da candidatura mais recente ──
                            Builder(
                              builder: (context) {
                                final latest = apps.first;
                                final reached = _stepReached(latest.status);
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FFFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE2F5EC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Progresso da Candidatura',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: kPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          const NexoraLogoIcon(size: 32),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  latest.jobTitle,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: Color(0xFF1A2E2A),
                                                  ),
                                                ),
                                                Text(
                                                  _descriptionFor(
                                                    latest,
                                                    jobDescriptions,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF4A5568),
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .calendar_today_outlined,
                                                      size: 11,
                                                      color: Color(0xFF8A9BA8),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Submetida em ${_fmt(latest.appliedAt)}',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF8A9BA8,
                                                        ),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ApplicationDetailScreen(
                                                      application: latest,
                                                    ),
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: kPrimary,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Ver Detalhes',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Divider(color: Colors.grey.shade200),
                                      const SizedBox(height: 10),
                                      _TimelineStep(
                                        done: reached > 0,
                                        current: reached == 0,
                                        icon: Icons.check,
                                        title: 'Candidatura Recebida',
                                        isLast: false,
                                      ),
                                      _TimelineStep(
                                        done: reached > 1,
                                        current: reached == 1,
                                        icon: Icons.rate_review_outlined,
                                        title: 'Em Análise',
                                        isLast: false,
                                      ),
                                      _TimelineStep(
                                        done: reached > 2,
                                        current: reached == 2,
                                        icon: Icons.person_outline,
                                        title: 'Entrevista',
                                        isLast: false,
                                      ),
                                      _TimelineStep(
                                        done: false,
                                        current: reached == 3,
                                        icon: Icons.flag_outlined,
                                        title:
                                            latest.status ==
                                                ApplicationStatus.rejected
                                            ? 'Não Seleccionada'
                                            : 'Decisão',
                                        isLast: true,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _descriptionFor(Application app, Map<int, String> descriptions) {
    final fromApplication = app.jobDescription.trim();
    if (fromApplication.isNotEmpty) return fromApplication;

    final fromJob = descriptions[app.jobId]?.trim();
    if (fromJob != null && fromJob.isNotEmpty) return fromJob;

    return 'Descri\u00e7\u00e3o da vaga indispon\u00edvel.';
  }
}

// ── Application card ──
class _AppCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String status;
  final Color statusColor;

  const _AppCard({
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const NexoraLogoIcon(size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A2E2A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade300,
                size: 13,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Timeline step (versão compacta) ──
class _TimelineStep extends StatelessWidget {
  final bool done;
  final bool current;
  final IconData icon;
  final String title;
  final bool isLast;

  const _TimelineStep({
    required this.done,
    required this.current,
    required this.icon,
    required this.title,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? kPrimary : Colors.white,
                  border: Border.all(
                    color: (done || current) ? kPrimary : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  done ? Icons.check : icon,
                  color: done
                      ? Colors.white
                      : (current ? kPrimary : Colors.grey.shade400),
                  size: 15,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: done ? kPrimary : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: current
                      ? kPrimary
                      : (done ? const Color(0xFF1A2E2A) : Colors.grey.shade500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
