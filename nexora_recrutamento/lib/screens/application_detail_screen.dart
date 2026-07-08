import 'package:flutter/material.dart';
import '../features/applications/domain/entities/application.dart';
import '../widgets/nexora_logo.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final Application application;

  const ApplicationDetailScreen({super.key, required this.application});

  Color get _statusColor {
    switch (application.status) {
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
    switch (application.status) {
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

  int get _stepReached {
    switch (application.status) {
      case ApplicationStatus.inReview:
        return 1;
      case ApplicationStatus.interview:
        return 2;
      case ApplicationStatus.approved:
        return 3;
      case ApplicationStatus.rejected:
        return 3;
      default:
        return 0;
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Detalhe da Candidatura',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              application.status.pt,
                              style: TextStyle(
                                color: _statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: NexoraLogoIcon(size: 30, isWhite: true),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  application.jobTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      application.company,
                                      style: const TextStyle(
                                        color: Color.fromRGBO(255, 255, 255, 0.85),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified,
                                        color: Colors.white, size: 14),
                                  ],
                                ),
                                if (application.trackingCode != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Código: ${application.trackingCode}',
                                    style: const TextStyle(
                                      color: Color.fromRGBO(255, 255, 255, 0.7),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            'Submetida em ${_fmt(application.appliedAt)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Timeline ──
                      _SectionCard(
                        title: 'Progresso da Candidatura',
                        child: Column(
                          children: [
                            _TimelineStep(
                              label: 'Recebida',
                              sublabel: 'Candidatura submetida',
                              stepIndex: 0,
                              reached: _stepReached,
                              isLast: false,
                            ),
                            _TimelineStep(
                              label: 'Em Análise',
                              sublabel: 'Perfil em avaliação',
                              stepIndex: 1,
                              reached: _stepReached,
                              isLast: false,
                            ),
                            _TimelineStep(
                              label: 'Entrevista',
                              sublabel: application.interviewDate != null
                                  ? 'Agendada para ${_fmt(application.interviewDate!)}'
                                  : 'Ainda não agendada',
                              stepIndex: 2,
                              reached: _stepReached,
                              isLast: false,
                            ),
                            _TimelineStep(
                              label: 'Decisão',
                              sublabel: application.status ==
                                      ApplicationStatus.rejected
                                  ? 'Não seleccionada desta vez'
                                  : 'Decisão final da candidatura',
                              stepIndex: 3,
                              reached: _stepReached,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),

                      if (application.interviewDate != null ||
                          application.interviewLocation != null ||
                          application.interviewLink != null) ...[
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: 'Entrevista',
                          child: Column(
                            children: [
                              if (application.interviewDate != null)
                                _DetailRow(
                                  icon: Icons.event_outlined,
                                  label: 'Data',
                                  value:
                                      '${_fmt(application.interviewDate!)} às ${application.interviewDate!.hour.toString().padLeft(2, '0')}:${application.interviewDate!.minute.toString().padLeft(2, '0')}',
                                ),
                              if (application.interviewLocation != null)
                                _DetailRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Local',
                                  value: application.interviewLocation!,
                                ),
                              if (application.interviewLink != null)
                                _DetailRow(
                                  icon: Icons.link,
                                  label: 'Link',
                                  value: application.interviewLink!,
                                  isLast: true,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
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

// ── Section card ──
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1A2E2A),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Timeline step ──
class _TimelineStep extends StatelessWidget {
  final String label;
  final String sublabel;
  final int stepIndex;
  final int reached;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.sublabel,
    required this.stepIndex,
    required this.reached,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = stepIndex < reached;
    final isCurrent = stepIndex == reached;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? kPrimary : Colors.white,
                  border: Border.all(
                    color: (isDone || isCurrent) ? kPrimary : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check : (isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  size: 14,
                  color: isDone
                      ? Colors.white
                      : (isCurrent ? kPrimary : Colors.grey.shade400),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: isDone ? kPrimary : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: isCurrent
                          ? kPrimary
                          : (isDone
                              ? const Color(0xFF1A2E2A)
                              : Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          if (isDone)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Concluído',
                  style: TextStyle(
                      color: kPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Actual',
                  style: TextStyle(
                      color: Color(0xFF4A90D9),
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Detail row ──
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimary, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1A2E2A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
