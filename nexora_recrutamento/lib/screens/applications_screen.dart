import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';
import 'application_detail_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  static const _apps = [
    _AppData(
      title: 'Product Designer',
      company: 'Google',
      location: 'Bangalore, India',
      date: 'May 20, 2025',
      status: 'Received',
      logoBg: Color(0xFF1A1A2E),
      logoText: 'G',
      isGoogle: true,
    ),
    _AppData(
      title: 'UX Researcher',
      company: 'Amazon',
      location: 'Hyderabad, India',
      date: 'May 18, 2025',
      status: 'In Review',
      logoBg: Color(0xFF1A1A1A),
      logoText: 'amazon',
    ),
    _AppData(
      title: 'Senior Product Designer',
      company: 'Upwork',
      location: 'Remote',
      date: 'May 15, 2025',
      status: 'Interview',
      logoBg: Color(0xFF1DBF73),
      logoText: 'up',
    ),
    _AppData(
      title: 'UI/UX Designer',
      company: 'Microsoft',
      location: 'Noida, India',
      date: 'May 10, 2025',
      status: 'Received',
      logoBg: Color(0xFF1A1A2E),
      logoText: 'MS',
      isMicrosoft: true,
    ),
    _AppData(
      title: 'Product Design Intern',
      company: 'Airbnb',
      location: 'Remote',
      date: 'May 8, 2025',
      status: 'In Review',
      logoBg: Color(0xFFFF5A5F),
      logoText: 'A',
    ),
  ];

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
                        'My Applications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Track your job applications and their status',
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
                    // Search + filter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
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
                                      decoration: InputDecoration(
                                        hintText: 'Search applications',
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
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.tune,
                              color: kPrimary,
                              size: 18,
                            ),
                            label: const Text(
                              'Filter',
                              style: TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Application list
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _apps.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApplicationDetailScreen(
                                title: _apps[i].title,
                                company: _apps[i].company,
                                location: _apps[i].location,
                                date: _apps[i].date,
                                status: _apps[i].status,
                                logoBg: _apps[i].logoBg,
                                logoText: _apps[i].logoText,
                                isGoogle: _apps[i].isGoogle,
                                isMicrosoft: _apps[i].isMicrosoft,
                              ),
                            ),
                          ),
                          child: _ApplicationCard(app: _apps[i]),
                        ),
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

class _AppData {
  final String title;
  final String company;
  final String location;
  final String date;
  final String status;
  final Color logoBg;
  final String logoText;
  final bool isGoogle;
  final bool isMicrosoft;

  const _AppData({
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
}

class _ApplicationCard extends StatelessWidget {
  final _AppData app;
  const _ApplicationCard({required this.app});

  Color get _statusColor {
    switch (app.status) {
      case 'Interview':
        return const Color(0xFFE57C00);
      case 'In Review':
        return const Color(0xFF4A90D9);
      default:
        return kPrimary;
    }
  }

  Color get _statusBg {
    switch (app.status) {
      case 'Interview':
        return const Color(0xFFFFF3E8);
      case 'In Review':
        return const Color(0xFFEBF3FF);
      default:
        return const Color(0xFFE8F8F0);
    }
  }

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
                _buildLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: Color(0xFF1A2E2A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            app.company,
                            style: const TextStyle(
                              color: Color(0xFF4A5568),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: kPrimary, size: 13),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            app.location,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
                  app.date,
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
                    app.status,
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
              label: 'Message Recruiter',
              color: kPrimary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    name: 'Recruiter · ${app.company}',
                    role: 'Talent Acquisition',
                    company: app.company,
                    avatarColor: app.logoBg == const Color(0xFF1A1A2E) ||
                            app.logoBg == const Color(0xFF1A1A1A)
                        ? const Color(0xFF7A9BB5)
                        : app.logoBg,
                    online: false,
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
    if (app.isMicrosoft) {
      const sq = 13.0;
      const gap = 2.5;
      return Container(
        width: 50,
        height: 50,
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
                  Container(
                    width: sq,
                    height: sq,
                    color: const Color(0xFFF25022),
                  ),
                  const SizedBox(width: gap),
                  Container(
                    width: sq,
                    height: sq,
                    color: const Color(0xFF7FBA00),
                  ),
                ],
              ),
              const SizedBox(height: gap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: sq,
                    height: sq,
                    color: const Color(0xFF00A4EF),
                  ),
                  const SizedBox(width: gap),
                  Container(
                    width: sq,
                    height: sq,
                    color: const Color(0xFFFFB900),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: app.logoBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          app.logoText,
          style: TextStyle(
            color: app.logoBg == Colors.white ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: app.logoText.length > 2 ? 9 : 16,
          ),
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
