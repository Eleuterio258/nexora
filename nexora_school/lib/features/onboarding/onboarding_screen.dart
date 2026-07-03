import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      image: AppAssets.onboarding1,
      title: 'Acompanhe as suas Notas',
      body:  'Veja o seu desempenho em todas as disciplinas em tempo real.',
    ),
    _OnboardingPageData(
      image: AppAssets.onboarding2,
      title: 'O Seu Horário Sempre à Mão',
      body:  'Consulte as aulas do dia, semana, e receba lembretes automáticos.',
    ),
    _OnboardingPageData(
      image: AppAssets.onboarding3,
      title: 'Fique Sempre Informado',
      body:  'Receba comunicados, tarefas e avisos da escola directamente no telemóvel.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  void _skip() => Navigator.of(context).pushReplacementNamed(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final bool isLast = _currentPage == _pages.length - 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Botão Saltar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(foregroundColor: AppColors.textGray),
                    child: const Text('Saltar', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ),

            // ── Páginas ─────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),

            // ── Indicadores ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // ── Botões ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isLast
                    ? SizedBox(
                        key: const ValueKey('last'),
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _skip,
                          child: const Text('Já tenho conta — Entrar'),
                        ),
                      )
                    : SizedBox(
                        key: const ValueKey('next'),
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _next,
                          child: const Text('Próximo'),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _OnboardingPageData {
  final String image;
  final String title;
  final String body;

  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.body,
  });
}

// ── Page widget ───────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustração principal
          SizedBox(
            width: size.width * 0.75,
            height: size.width * 0.75,
            child: Image.asset(
              data.image,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 40),

          // Título
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Descrição
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
