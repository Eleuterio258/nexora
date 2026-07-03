import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';

class ApplicationDetailScreen extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String date;
  final String status;
  final Color logoBg;
  final String logoText;
  final bool isGoogle;
  final bool isMicrosoft;

  const ApplicationDetailScreen({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.date,
    required this.status,
    required this.logoBg,
    required this.logoText,
    this.isGoogle = false,
    this.isMicrosoft = false,
  });

  Color get _statusColor {
    switch (status) {
      case 'Interview':
        return const Color(0xFFE57C00);
      case 'In Review':
        return const Color(0xFF4A90D9);
      default:
        return kPrimary;
    }
  }

  Color get _statusBg {
    switch (status) {
      case 'Interview':
        return const Color(0xFFFFF3E8);
      case 'In Review':
        return const Color(0xFFEBF3FF);
      default:
        return const Color(0xFFE8F8F0);
    }
  }

  int get _stepReached {
    switch (status) {
      case 'In Review':
        return 1;
      case 'Interview':
        return 2;
      case 'Offer':
        return 3;
      default:
        return 0;
    }
  }

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
                      // Top bar
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
                              'Application Details',
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
                              status,
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
                      // Company info row
                      Row(
                        children: [
                          _buildLogo(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
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
                                      company,
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
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        color: Color.fromRGBO(255, 255, 255, 0.7),
                                        size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        color: Color.fromRGBO(255, 255, 255, 0.7),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
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
                      // ── Applied date ──
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            'Applied on $date',
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
                        title: 'Application Progress',
                        child: Column(
                          children: [
                            _TimelineStep(
                              label: 'Applied',
                              sublabel: 'Application submitted',
                              stepIndex: 0,
                              reached: _stepReached,
                              isLast: false,
                            ),
                            _TimelineStep(
                              label: 'Screening',
                              sublabel: 'Profile under review',
                              stepIndex: 1,
                              reached: _stepReached,
                              isLast: false,
                            ),
                            _TimelineStep(
                              label: 'Interview',
                              sublabel: 'Interview scheduled',
                              stepIndex: 2,
                              reached: _stepReached,
                              isLast: false,
                            ),
                            _TimelineStep(
                              label: 'Decision',
                              sublabel: 'Final hiring decision',
                              stepIndex: 3,
                              reached: _stepReached,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Job details ──
                      _SectionCard(
                        title: 'Job Details',
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.work_outline,
                              label: 'Type',
                              value: 'Full-time',
                            ),
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: location,
                            ),
                            _DetailRow(
                              icon: Icons.attach_money_outlined,
                              label: 'Salary',
                              value: '\$80k – \$120k / year',
                            ),
                            _DetailRow(
                              icon: Icons.category_outlined,
                              label: 'Department',
                              value: 'Product & Design',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Documents ──
                      _SectionCard(
                        title: 'Submitted Documents',
                        child: Column(
                          children: const [
                            _DocumentRow(
                                icon: Icons.description_outlined,
                                name: 'Resume.pdf',
                                size: '248 KB'),
                            SizedBox(height: 10),
                            _DocumentRow(
                                icon: Icons.article_outlined,
                                name: 'Cover_Letter.pdf',
                                size: '95 KB'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Actions ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text(
                            'Message Recruiter',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
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

  Widget _buildLogo() {
    if (isMicrosoft) {
      const sq = 13.0;
      const gap = 2.5;
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: sq, height: sq, color: const Color(0xFFF25022)),
                const SizedBox(width: gap),
                Container(width: sq, height: sq, color: const Color(0xFF7FBA00)),
              ]),
              const SizedBox(height: gap),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: sq, height: sq, color: const Color(0xFF00A4EF)),
                const SizedBox(width: gap),
                Container(width: sq, height: sq, color: const Color(0xFFFFB900)),
              ]),
            ],
          ),
        ),
      );
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: logoBg,
        borderRadius: BorderRadius.circular(12),
        border: logoBg == Colors.white
            ? Border.all(color: const Color.fromRGBO(255, 255, 255, 0.3))
            : null,
      ),
      child: Center(
        child: Text(
          logoText,
          style: TextStyle(
            color: logoBg == Colors.white ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: logoText.length > 2 ? 10 : 18,
          ),
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
                  'Done',
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
                  'Active',
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
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A2E2A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
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

// ── Document row ──
class _DocumentRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String size;

  const _DocumentRow({
    required this.icon,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1A2E2A),
                ),
              ),
              Text(
                size,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: kPrimary, size: 18),
      ],
    );
  }
}
