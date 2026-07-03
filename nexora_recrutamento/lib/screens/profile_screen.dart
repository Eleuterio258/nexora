import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';
import 'notifications_screen.dart';
import 'personal_info_screen.dart';
import 'experience_screen.dart';
import 'education_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
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
                      const SizedBox(height: 20),
                      // Profile info row
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: const Color(0xFFB5937A),
                                child: ClipOval(
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    color: const Color(0xFF9B7560),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: kPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Arjun Mehta',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Product Manager',
                                  style: TextStyle(
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.75,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.work_outline,
                                      color: Color.fromRGBO(255, 255, 255, 0.7),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Building user-centric products that solve real-world problems.',
                                        style: TextStyle(
                                          color: const Color.fromRGBO(
                                            255,
                                            255,
                                            255,
                                            0.75,
                                          ),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.person_outline,
                        title: 'Personal Info',
                        subtitle: 'View and update your personal details',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
                      ),
                      const SizedBox(height: 14),
                      _MenuItem(
                        icon: Icons.work_outline,
                        title: 'Experience',
                        subtitle: 'Add and manage your work experience',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ExperienceScreen())),
                      ),
                      const SizedBox(height: 14),
                      _MenuItem(
                        icon: Icons.school_outlined,
                        title: 'Education',
                        subtitle: 'Add and manage your educational background',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const EducationScreen())),
                      ),
                      const SizedBox(height: 14),
                      _MenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Manage your account and preferences',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                      const SizedBox(height: 24),
                      // Complete profile card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FBF6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD6F0E4)),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCEEDD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const Icon(
                                  Icons.verified_user,
                                  color: kPrimary,
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Complete your profile',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF1A2E2A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'A complete profile increases your chances of getting hired.',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '85% Complete',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Icon(icon, color: kPrimary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A2E2A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kPrimary, size: 22),
          ],
        ),
      ),
    );
  }
}
