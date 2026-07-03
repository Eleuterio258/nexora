import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final List<_EduData> _education = [
    _EduData(
      degree: 'MBA – Product Management',
      institution: 'Indian Institute of Management',
      period: '2016 – 2018',
      location: 'Ahmedabad, India',
      grade: 'First Class with Distinction',
      logoBg: const Color(0xFF8A3F3F),
      logoText: 'IIM',
    ),
    _EduData(
      degree: 'B.Tech – Computer Science',
      institution: 'BITS Pilani',
      period: '2012 – 2016',
      location: 'Pilani, Rajasthan',
      grade: 'CGPA: 8.7 / 10',
      logoBg: const Color(0xFF4A5568),
      logoText: 'BITS',
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
          'Education',
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
      body: _education.isEmpty
          ? _EmptyState(
              icon: Icons.school_outlined,
              label: 'No education added yet',
              sub: 'Add your academic background',
              onAdd: () => _showAddSheet(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _education.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _EduCard(edu: _education[i]),
            ),
    );
  }

  void _showAddSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _AddEduScreen()),
    );
  }
}

class _EduData {
  final String degree;
  final String institution;
  final String period;
  final String location;
  final String grade;
  final Color logoBg;
  final String logoText;

  const _EduData({
    required this.degree,
    required this.institution,
    required this.period,
    required this.location,
    required this.grade,
    required this.logoBg,
    required this.logoText,
  });
}

class _EduCard extends StatelessWidget {
  final _EduData edu;
  const _EduCard({required this.edu});

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
                    color: edu.logoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(edu.logoText,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: edu.logoText.length > 2 ? 10 : 14,
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(edu.degree,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1A2E2A))),
                      const SizedBox(height: 3),
                      Text(edu.institution,
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
                Text(edu.period,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5)),
                const SizedBox(width: 12),
                Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(edu.location,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.grade_outlined, size: 13, color: kPrimary),
                const SizedBox(width: 5),
                Text(edu.grade,
                    style: const TextStyle(
                        color: kPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEduScreen extends StatelessWidget {
  const _AddEduScreen();

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
        title: const Text('Add Education',
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
            _SheetField(label: 'Degree / Course', icon: Icons.school_outlined),
            const SizedBox(height: 12),
            _SheetField(label: 'Institution', icon: Icons.account_balance_outlined),
            const SizedBox(height: 12),
            _SheetField(label: 'Location', icon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SheetField(label: 'Start Year', icon: Icons.calendar_today_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _SheetField(label: 'End Year', icon: Icons.calendar_today_outlined)),
            ]),
            const SizedBox(height: 12),
            _SheetField(label: 'Grade / CGPA', icon: Icons.grade_outlined),
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
                child: const Text('Add Education',
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
  const _SheetField({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: TextField(
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
              style:
                  const TextStyle(color: Color(0xFF9AA5B1), fontSize: 13)),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
