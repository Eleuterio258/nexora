import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../widgets/nexora_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _accents = [
    Color(0xFF2CB87A),
    Color(0xFF4A90D9),
    Color(0xFFE57C00),
    Color(0xFF2CB87A),
  ];

  static const _icons = [
    Icons.work_outline_rounded,
    Icons.send_rounded,
    Icons.track_changes_rounded,
    Icons.verified_rounded,
  ];

  void _next(int slideCount) {
    if (_page < slideCount - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final slides = s.onbSlides;
    final isLast = _page == slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                child: isLast
                    ? const SizedBox(height: 36)
                    : TextButton(
                        onPressed: _goLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF9AA5B1),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(s.onbSkip,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlidePage(
                  strings: slides[i],
                  accent: _accents[i],
                  icon: _icons[i],
                  chipLabel: _chipLabel(s, i),
                ),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? kPrimary
                              : const Color(0xFFCCE8DA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Main button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _next(slides.length),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? s.onbGetStarted : s.onbNext,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.onbHaveAccount,
                          style: const TextStyle(
                              color: Color(0xFF9AA5B1), fontSize: 13.5)),
                      GestureDetector(
                        onTap: _goLogin,
                        child: Text(s.onbSignIn,
                            style: const TextStyle(
                                color: kPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                      ),
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

  String _chipLabel(AppStrings s, int index) {
    switch (index) {
      case 0:
        return s.onbChipJobs;
      case 1:
        return s.onbChipApply;
      case 2:
        return s.onbChipTracking;
      default:
        return s.onbChipHired;
    }
  }
}

class _SlidePage extends StatelessWidget {
  final OnbSlideStrings strings;
  final Color accent;
  final IconData icon;
  final String chipLabel;

  const _SlidePage({
    required this.strings,
    required this.accent,
    required this.icon,
    required this.chipLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Illustration area
          Expanded(
            flex: 5,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Icon container
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 50),
                  ),
                  // Nexora logo badge top-right
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 10,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Center(child: NexoraLogoIcon(size: 22)),
                    ),
                  ),
                  // Floating stat chip bottom-left
                  Positioned(
                    bottom: 24,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 10,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            chipLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Text content
          Expanded(
            flex: 4,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  strings.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2E2A),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7E7A),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
