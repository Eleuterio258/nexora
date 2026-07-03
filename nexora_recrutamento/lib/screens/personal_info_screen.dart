import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameCtrl = TextEditingController(text: 'Arjun Mehta');
  final _emailCtrl = TextEditingController(text: 'arjun.mehta@gmail.com');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _locationCtrl = TextEditingController(text: 'Bangalore, India');
  final _titleCtrl = TextEditingController(text: 'Product Manager');
  final _bioCtrl = TextEditingController(
      text:
          'Building user-centric products that solve real-world problems. 5+ years in product management across fintech and edtech.');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

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
          'Personal Info',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF9B7560),
                    child: const Icon(Icons.person, color: Colors.white, size: 54),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: kPrimary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Tap to change photo',
                  style: TextStyle(color: Color(0xFF9AA5B1), fontSize: 13)),
            ),
            const SizedBox(height: 28),
            _SectionLabel('Basic Details'),
            const SizedBox(height: 12),
            _Field(label: 'Full Name', controller: _nameCtrl, icon: Icons.person_outline),
            const SizedBox(height: 12),
            _Field(label: 'Job Title', controller: _titleCtrl, icon: Icons.work_outline),
            const SizedBox(height: 12),
            _Field(label: 'Location', controller: _locationCtrl, icon: Icons.location_on_outlined),
            const SizedBox(height: 24),
            _SectionLabel('Contact'),
            const SizedBox(height: 12),
            _Field(label: 'Email', controller: _emailCtrl, icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _Field(label: 'Phone', controller: _phoneCtrl, icon: Icons.phone_outlined, keyboard: TextInputType.phone),
            const SizedBox(height: 24),
            _SectionLabel('About'),
            const SizedBox(height: 12),
            _Field(label: 'Bio', controller: _bioCtrl, icon: Icons.notes_outlined, maxLines: 4),
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
                child: const Text('Save Changes',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9AA5B1),
            letterSpacing: 0.5));
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboard;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: Color(0xFF9AA5B1), fontSize: 13),
          prefixIcon: Icon(icon, color: kPrimary, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
