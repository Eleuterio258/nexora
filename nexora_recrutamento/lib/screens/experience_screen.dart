import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key});

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  final List<_ExpData> _experiences = [
    _ExpData(
      title: 'Senior Product Manager',
      company: 'Nexora Technologies',
      period: 'Jan 2022 – Present',
      location: 'Bangalore, India',
      description: 'Led cross-functional teams to ship 3 major product lines. Increased DAU by 40% and reduced churn by 18% through data-driven improvements.',
      logoBg: kPrimary,
      logoText: 'N',
      current: true,
    ),
    _ExpData(
      title: 'Product Manager',
      company: 'CloudScale Inc.',
      period: 'Mar 2020 – Dec 2021',
      location: 'Hyderabad, India',
      description: 'Owned the B2B SaaS product roadmap. Launched 5 enterprise features that contributed to 60% ARR growth.',
      logoBg: const Color(0xFF4A90D9),
      logoText: 'C',
      current: false,
    ),
    _ExpData(
      title: 'Associate Product Manager',
      company: 'BrightWare Solutions',
      period: 'Jun 2018 – Feb 2020',
      location: 'Pune, India',
      description: 'Managed consumer-facing mobile app. Coordinated with engineering and design to deliver quarterly releases.',
      logoBg: const Color(0xFFE57C00),
      logoText: 'B',
      current: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5EE),
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Experience',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: _experiences.isEmpty
          ? _EmptyState(
              icon: Icons.work_outline,
              label: 'No experience added yet',
              sub: 'Add your work history to stand out',
              onAdd: () => _showAddSheet(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _experiences.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ExpCard(exp: _experiences[i]),
            ),
    );
  }

  void _showAddSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _AddExpScreen()),
    );
  }
}

class _ExpData {
  final String title;
  final String company;
  final String period;
  final String location;
  final String description;
  final Color logoBg;
  final String logoText;
  final bool current;

  const _ExpData({
    required this.title,
    required this.company,
    required this.period,
    required this.location,
    required this.description,
    required this.logoBg,
    required this.logoText,
    required this.current,
  });
}

class _ExpCard extends StatelessWidget {
  final _ExpData exp;
  const _ExpCard({required this.exp});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: exp.logoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(exp.logoText,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: exp.logoText.length > 2 ? 9 : 15,
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(exp.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: Color(0xFF1A2E2A))),
                          ),
                          if (exp.current)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Current',
                                  style: TextStyle(
                                      color: kPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(exp.company,
                          style: const TextStyle(
                              color: Color(0xFF4A5568),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 5),
                Text(exp.period,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12.5)),
                const SizedBox(width: 12),
                Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(exp.location,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12.5)),
              ],
            ),
            const SizedBox(height: 10),
            Text(exp.description,
                style: const TextStyle(
                    color: Color(0xFF4A5568), fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _AddExpScreen extends StatelessWidget {
  const _AddExpScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5EE),
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Experience',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetField(label: 'Job Title', icon: Icons.work_outline),
            const SizedBox(height: 12),
            _SheetField(label: 'Company', icon: Icons.business_outlined),
            const SizedBox(height: 12),
            _SheetField(label: 'Location', icon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SheetField(label: 'Start Date', icon: Icons.calendar_today_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _SheetField(label: 'End Date', icon: Icons.calendar_today_outlined)),
            ]),
            const SizedBox(height: 12),
            _SheetField(label: 'Description', icon: Icons.notes_outlined, maxLines: 4),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Experience',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final IconData icon;
  final int maxLines;
  const _SheetField(
      {required this.label, required this.icon, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: Color(0xFF9AA5B1), fontSize: 13),
          prefixIcon: Icon(icon, color: kPrimary, size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onAdd;
  const _EmptyState(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: kPrimary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1A2E2A))),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(color: Color(0xFF9AA5B1), fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Now',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
