import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';
import 'applications_screen.dart';
import 'application_detail_screen.dart';
import 'job_details_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                                  builder: (_) =>
                                      const NotificationsScreen()),
                            ),
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_outlined,
                                    color: Colors.white, size: 26),
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
                          const SizedBox(width: 14),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF8BCFB0),
                            child: ClipOval(
                              child: Container(
                                color: const Color(0xFFB5937A),
                                child: const Icon(Icons.person,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Hi, Alex! 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Track your applications and\ntake the next step toward your dream job.',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // My Applications header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Applications',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2E2A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const ApplicationsScreen())),
                            child: Row(
                              children: const [
                                Text('View All',
                                    style: TextStyle(
                                        color: kPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Icon(Icons.chevron_right,
                                    color: kPrimary, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ApplicationDetailScreen(
                            title: 'UX Designer', company: 'Microsoft',
                            location: 'Noida, India', date: 'May 20, 2025',
                            status: 'Interview', logoBg: Color(0xFF1A1A2E),
                            logoText: 'MS', isMicrosoft: true,
                          ))),
                        child: _AppCard(
                          logo: _MsLogo(),
                          title: 'UX Designer',
                          company: 'Microsoft',
                          date: 'May 20, 2025',
                          status: 'Interview',
                          statusColor: kPrimary,
                          statusBg: const Color(0xFFE8F8F0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ApplicationDetailScreen(
                            title: 'Product Manager', company: 'Google',
                            location: 'Bangalore, India', date: 'May 15, 2025',
                            status: 'In Review', logoBg: Color(0xFF1A1A2E),
                            logoText: 'G', isGoogle: true,
                          ))),
                        child: _AppCard(
                          logo: _GoogleLogoSmall(),
                          title: 'Product Manager',
                          company: 'Google',
                          date: 'May 15, 2025',
                          status: 'In Review',
                          statusColor: const Color(0xFF4A90D9),
                          statusBg: const Color(0xFFEBF3FF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ApplicationDetailScreen(
                            title: 'Business Analyst', company: 'Deloitte',
                            location: 'Remote', date: 'May 10, 2025',
                            status: 'Received', logoBg: Color(0xFF1A1A1A),
                            logoText: 'D',
                          ))),
                        child: _AppCard(
                          logo: _TextLogo(
                              text: 'Deloitte.',
                              bg: const Color(0xFF1A1A1A),
                              fg: Colors.white,
                              fontSize: 7.5),
                          title: 'Business Analyst',
                          company: 'Deloitte',
                          date: 'May 10, 2025',
                          status: 'Received',
                          statusColor: const Color(0xFF888888),
                          statusBg: const Color(0xFFF2F2F2),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Application Progress card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FFFC),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: const Color(0xFFE2F5EC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Application Progress',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                                Icon(Icons.more_vert,
                                    color: Colors.grey.shade400, size: 20),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Job row
                            Row(
                              children: [
                                _MsLogo(size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('UX Designer',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF1A2E2A))),
                                      const Text('Microsoft',
                                          style: TextStyle(
                                              color: Color(0xFF8A9BA8),
                                              fontSize: 12)),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: const [
                                          Icon(Icons.calendar_today_outlined,
                                              size: 11,
                                              color: Color(0xFF8A9BA8)),
                                          SizedBox(width: 4),
                                          Text('Applied on May 20, 2025',
                                              style: TextStyle(
                                                  color: Color(0xFF8A9BA8),
                                                  fontSize: 11)),
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
                                            const JobDetailsScreen()),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('View Details',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(color: Colors.grey.shade200),
                            const SizedBox(height: 10),
                            // Timeline
                            _TimelineStep(
                              status: _StepStatus.done,
                              icon: Icons.check,
                              title: 'Application Received',
                              subtitle:
                                  'Your application has been received successfully.',
                              date: 'May 20, 2025',
                              isLast: false,
                            ),
                            _TimelineStep(
                              status: _StepStatus.done,
                              icon: Icons.check,
                              title: 'In Review',
                              subtitle:
                                  'Your application is being reviewed by the hiring team.',
                              date: 'May 22, 2025',
                              isLast: false,
                            ),
                            _TimelineStep(
                              status: _StepStatus.current,
                              icon: Icons.person_outline,
                              title: 'Interview',
                              subtitle:
                                  "You've been shortlisted for an interview.",
                              date: 'May 25, 2025',
                              isLast: false,
                            ),
                            _TimelineStep(
                              status: _StepStatus.pending,
                              icon: Icons.assignment_outlined,
                              title: 'Assessment',
                              subtitle:
                                  'Complete the assessment to move forward.',
                              date: 'Pending',
                              isLast: false,
                            ),
                            _TimelineStep(
                              status: _StepStatus.pending,
                              icon: Icons.flag_outlined,
                              title: 'Decision',
                              subtitle:
                                  "We'll notify you once a decision is made.",
                              date: 'Pending',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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

// ── Application card ──
class _AppCard extends StatelessWidget {
  final Widget logo;
  final String title;
  final String company;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusBg;

  const _AppCard({
    required this.logo,
    required this.title,
    required this.company,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.statusBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logo,
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
                  company,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11.5),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
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
              ),
              const SizedBox(height: 8),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey.shade300, size: 13),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Timeline step ──
enum _StepStatus { done, current, pending }

class _TimelineStep extends StatelessWidget {
  final _StepStatus status;
  final IconData icon;
  final String title;
  final String subtitle;
  final String date;
  final bool isLast;

  const _TimelineStep({
    required this.status,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == _StepStatus.done;
    final isCurrent = status == _StepStatus.current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle + line
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? kPrimary : Colors.white,
                  border: Border.all(
                    color: (isDone || isCurrent)
                        ? kPrimary
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check : icon,
                  color: isDone
                      ? Colors.white
                      : (isCurrent ? kPrimary : Colors.grey.shade400),
                  size: 15,
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
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isCurrent
                                ? kPrimary
                                : (status == _StepStatus.pending
                                    ? Colors.grey.shade500
                                    : const Color(0xFF1A2E2A)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          color: isCurrent ? kPrimary : Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (isDone) ...[
                        const SizedBox(height: 2),
                        Icon(Icons.check, color: kPrimary, size: 13),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Company logo helpers ──
class _MsLogo extends StatelessWidget {
  final double size;
  const _MsLogo({this.size = 48});

  @override
  Widget build(BuildContext context) {
    final gap = size * 0.06;
    final sq = (size * 0.62 - gap) / 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: sq, height: sq, color: const Color(0xFFF25022)),
                SizedBox(width: gap),
                Container(width: sq, height: sq, color: const Color(0xFF7FBA00)),
              ],
            ),
            SizedBox(height: gap),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: sq, height: sq, color: const Color(0xFF00A4EF)),
                SizedBox(width: gap),
                Container(width: sq, height: sq, color: const Color(0xFFFFB900)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoSmall extends StatelessWidget {
  final double size;
  const _GoogleLogoSmall({this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.6,
          height: size * 0.6,
          child: CustomPaint(painter: _MiniGooglePainter()),
        ),
      ),
    );
  }
}

class _MiniGooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.43;
    final sw = size.width * 0.19;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, -2.2, 2.4, false, p(const Color(0xFFEA4335)));
    canvas.drawArc(rect, 0.2, 1.35, false, p(const Color(0xFF4285F4)));
    canvas.drawArc(rect, 1.55, 0.48, false, p(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 2.03, 0.42, false, p(const Color(0xFF34A853)));
    canvas.drawLine(
      Offset(cx, cy - sw * 0.05),
      Offset(cx + r + sw * 0.45, cy - sw * 0.05),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = sw * 0.78
        ..strokeCap = StrokeCap.butt
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TextLogo extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final double fontSize;
  final double size;

  const _TextLogo({
    required this.text,
    required this.bg,
    required this.fg,
    this.fontSize = 11,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
