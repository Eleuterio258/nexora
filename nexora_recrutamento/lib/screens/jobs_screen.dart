import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';
import 'job_details_screen.dart';
import 'notifications_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _selectedCategory = 0;
  final _categories = ['All', 'Engineering', 'Design', 'Marketing', 'Sales'];

  final _jobs = const [
    _JobData(
      title: 'Senior Frontend Developer',
      company: 'Shopify',
      location: 'Ottawa, Canada',
      tags: ['Full-time'],
      time: '2h ago',
      logoColor: Color(0xFF5A8A2C),
      logoText: 'S',
    ),
    _JobData(
      title: 'Product Manager',
      company: 'Google',
      location: 'Mountain View, CA, USA',
      tags: ['Full-time'],
      time: '5h ago',
      logoColor: Color(0xFFFFFFFF),
      logoText: 'G',
      isGoogle: true,
    ),
    _JobData(
      title: 'UX Designer',
      company: 'Microsoft',
      location: 'Redmond, WA, USA',
      tags: ['Full-time'],
      time: '1d ago',
      logoColor: Color(0xFF1A1A2E),
      logoText: 'MS',
      isMicrosoft: true,
    ),
    _JobData(
      title: 'Software Engineer',
      company: 'Notion',
      location: 'San Francisco, CA, USA',
      tags: ['Full-time', 'Remote'],
      time: '2d ago',
      logoColor: Color(0xFF1A1A1A),
      logoText: 'N',
    ),
    _JobData(
      title: 'Data Analyst',
      company: 'Airbnb',
      location: 'New York, NY, USA',
      tags: ['Full-time'],
      time: '3d ago',
      logoColor: Color(0xFFFF5A5F),
      logoText: 'A',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5EE),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nexora',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kPrimary,
                        ),
                      ),
                      Text(
                        'Job Board',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            size: 26, color: Color(0xFF1A2E2A)),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search, color: kPrimary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search jobs, companies, or keywords',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Icon(Icons.tune, color: kPrimary, size: 20),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Category chips
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final active = i == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? kPrimary : const Color(0xFFDDDDDD),
                          ),
                        ),
                        child: Text(
                          _categories[i],
                          style: TextStyle(
                            color: active ? Colors.white : Colors.grey.shade600,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Job list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _JobCard(
                  job: _jobs[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const JobDetailsScreen()),
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

class _JobData {
  final String title;
  final String company;
  final String location;
  final List<String> tags;
  final String time;
  final Color logoColor;
  final String logoText;
  final bool isGoogle;
  final bool isMicrosoft;

  const _JobData({
    required this.title,
    required this.company,
    required this.location,
    required this.tags,
    required this.time,
    required this.logoColor,
    required this.logoText,
    this.isGoogle = false,
    this.isMicrosoft = false,
  });
}

class _JobCard extends StatefulWidget {
  final _JobData job;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.onTap});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            _buildLogo(job),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A2E2A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _saved ? Icons.bookmark : Icons.bookmark_border,
                          color: const Color(0xFF1A2E2A),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _saved = !_saved),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        job.company,
                        style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: kPrimary, size: 14),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(job.location,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...job.tags.map((t) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                    color: kPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          )),
                      const Spacer(),
                      Text(job.time,
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(_JobData job) {
    if (job.isMicrosoft) {
      final sq = 14.0;
      final gap = 3.0;
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
                SizedBox(width: gap),
                Container(width: sq, height: sq, color: const Color(0xFF7FBA00)),
              ]),
              SizedBox(height: gap),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: sq, height: sq, color: const Color(0xFF00A4EF)),
                SizedBox(width: gap),
                Container(width: sq, height: sq, color: const Color(0xFFFFB900)),
              ]),
            ],
          ),
        ),
      );
    }
    if (job.isGoogle) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CustomPaint(painter: _GooglePainter()),
          ),
        ),
      );
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: job.logoColor,
        borderRadius: BorderRadius.circular(12),
        border: job.logoColor == Colors.white
            ? Border.all(color: const Color(0xFFEEEEEE))
            : null,
      ),
      child: Center(
        child: Text(
          job.logoText,
          style: TextStyle(
            color: job.logoColor == Colors.white
                ? Colors.black87
                : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
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
