import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

/// Mostra a animacao de arranque e, assim que o [AuthBloc] souber se ha
/// sessao guardada, navega sozinho para /home ou /onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minSplashDuration = Duration(seconds: 3);

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAuthResolved(AuthState state) async {
    await Future.delayed(_minSplashDuration);
    if (!mounted) return;

    final destination = state is AuthAuthenticated ? '/home' : '/onboarding';
    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthUnauthenticated) {
          _onAuthResolved(state);
        }
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.primaryDark,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  AppAssets.splashBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        AppColors.primaryDark.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: SizedBox(
                      width: size.width * 0.62,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: SvgPicture.asset(
                          AppAssets.nexoraLogoWhite,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: bottomInset + size.height * 0.04,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: size.width * 0.45,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Versao 1.0.0',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: size.width * 0.03,
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
    );
  }
}
