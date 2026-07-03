import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  int _tab = 0;
  bool _descExpanded = true;
  bool _reqExpanded = true;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            NexoraLogoIcon(size: 22),
            SizedBox(width: 8),
            Text(
              'NEXORA',
              style: TextStyle(
                color: Color(0xFF1A2E2A),
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFF1A2E2A),
            ),
            onPressed: () => setState(() => _saved = !_saved),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Senior Full Stack\nDeveloper',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2E2A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Meta chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        _MetaChip(icon: Icons.work_outline, label: 'Engineering'),
                        SizedBox(width: 10),
                        _MetaChip(icon: Icons.location_on_outlined, label: 'Bangalore, India'),
                        SizedBox(width: 10),
                        _MetaChip(icon: Icons.business_outlined, label: 'Hybrid'),
                        SizedBox(width: 10),
                        _MetaChip(icon: Icons.attach_money_outlined, label: '₹18 - ₹30 LPA'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Company card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: NexoraLogoIcon(size: 30, isWhite: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Flexible(
                                    child: Text(
                                      'Nexora Technologies',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF1A2E2A),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.verified, color: kPrimary, size: 16),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Building innovative digital solutions that\nempower businesses worldwide.',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kPrimary),
                            foregroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('View Company',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tab bar
                  Row(
                    children: [
                      _TabItem(
                          label: 'Job Description',
                          active: _tab == 0,
                          onTap: () => setState(() => _tab = 0)),
                      const SizedBox(width: 24),
                      _TabItem(
                          label: 'Requirements',
                          active: _tab == 1,
                          onTap: () => setState(() => _tab = 1)),
                      const SizedBox(width: 24),
                      _TabItem(
                          label: 'Benefits',
                          active: _tab == 2,
                          onTap: () => setState(() => _tab = 2)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // ── Tab 0: Job Description ──
                  if (_tab == 0) ...[
                    _ExpandableSection(
                      icon: Icons.description_outlined,
                      title: 'About the Role',
                      expanded: _descExpanded,
                      onToggle: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: const Text(
                        'We are looking for a passionate and experienced Senior Full Stack Developer to join our dynamic engineering team. You will be responsible for designing, developing, and maintaining scalable web applications that deliver exceptional user experiences.\n\nYou will collaborate with cross-functional teams to define, design, and ship new features, and help shape the technical direction of our products.',
                        style: TextStyle(
                            color: Color(0xFF4A5568), fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ExpandableSection(
                      icon: Icons.work_history_outlined,
                      title: 'Responsibilities',
                      expanded: _reqExpanded,
                      onToggle: () =>
                          setState(() => _reqExpanded = !_reqExpanded),
                      child: Column(
                        children: const [
                          _BulletItem('Design and implement scalable backend services and REST APIs'),
                          _BulletItem('Build responsive, high-performance frontend interfaces with React'),
                          _BulletItem('Collaborate with product and design teams on feature delivery'),
                          _BulletItem('Conduct code reviews and mentor junior engineers'),
                          _BulletItem('Ensure application security, performance, and reliability'),
                        ],
                      ),
                    ),
                  ],

                  // ── Tab 1: Requirements ──
                  if (_tab == 1) ...[
                    _ExpandableSection(
                      icon: Icons.school_outlined,
                      title: 'Qualifications',
                      expanded: _descExpanded,
                      onToggle: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Column(
                        children: const [
                          _BulletItem('Bachelor\'s degree in Computer Science or related field'),
                          _BulletItem('5+ years of experience in full stack development'),
                          _BulletItem('Strong proficiency in JavaScript, TypeScript and React'),
                          _BulletItem('Experience with Node.js, Express or similar backend frameworks'),
                          _BulletItem('Knowledge of PostgreSQL, MongoDB or Redis'),
                          _BulletItem('Familiarity with RESTful APIs and GraphQL'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ExpandableSection(
                      icon: Icons.star_outline,
                      title: 'Nice to Have',
                      expanded: _reqExpanded,
                      onToggle: () =>
                          setState(() => _reqExpanded = !_reqExpanded),
                      child: Column(
                        children: const [
                          _BulletItem('Experience with cloud platforms (AWS, GCP or Azure)'),
                          _BulletItem('Knowledge of Docker and Kubernetes'),
                          _BulletItem('Open source contributions'),
                          _BulletItem('Experience in an Agile/Scrum environment'),
                        ],
                      ),
                    ),
                  ],

                  // ── Tab 2: Benefits ──
                  if (_tab == 2) ...[
                    _BenefitCard(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Health & Wellness',
                      items: const [
                        'Full medical, dental and vision coverage',
                        'Mental health support & counselling sessions',
                        'Annual wellness budget of ₹25,000',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _BenefitCard(
                      icon: Icons.laptop_outlined,
                      title: 'Work Flexibility',
                      items: const [
                        'Hybrid work model (3 days remote)',
                        'Flexible working hours',
                        'Home office setup allowance ₹30,000',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _BenefitCard(
                      icon: Icons.trending_up_outlined,
                      title: 'Growth & Learning',
                      items: const [
                        'Annual learning budget of ₹50,000',
                        'Access to online courses & certifications',
                        'Conference attendance sponsorship',
                        'Internal mentorship programme',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _BenefitCard(
                      icon: Icons.celebration_outlined,
                      title: 'Perks & Culture',
                      items: const [
                        '26 days paid leave + public holidays',
                        'Team retreats twice a year',
                        'Free meals at office cafeteria',
                        'Employee stock option plan (ESOP)',
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom action bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary row: salary + Apply Now
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Salary',
                                style: TextStyle(
                                  color: Color(0xFF9AA5B1),
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: const [
                                  Text(
                                    '₹18 – 30',
                                    style: TextStyle(
                                      color: Color(0xFF1A2E2A),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LPA',
                                    style: TextStyle(
                                      color: Color(0xFF9AA5B1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text(
                              'Apply Now',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Secondary actions row
                    Row(
                      children: [
                        Expanded(
                          child: _BarAction(
                            icon: Icons.bookmark_border_rounded,
                            label: 'Save Job',
                            onTap: () => setState(() => _saved = !_saved),
                            active: _saved,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BarAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Message',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BarAction(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabItem(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? kPrimary : Colors.grey.shade500,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          if (active)
            Container(
              height: 2,
              width: label.length * 7.0,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A2E2A),
                  ),
                ),
              ),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 14),
          child,
        ],
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: kPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFF4A5568), fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A2E2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
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

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFE8F8F0)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? kPrimary : const Color(0xFF4A5568),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? kPrimary : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
