import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        } else if (state is AuthUnauthenticated || state is AuthFailure) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fingerprint, size: 80, color: AppColors.brandAccent),
              SizedBox(height: 24),
              Text(
                'Nexora',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: AppColors.brandAccent),
            ],
          ),
        ),
      ),
    );
  }
}
