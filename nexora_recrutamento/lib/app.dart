import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/app_navigator.dart';
import 'core/push/push_notification_service.dart';
import 'features/applications/presentation/bloc/application_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/jobs/presentation/bloc/job_bloc.dart';
import 'features/messages/presentation/bloc/messages_bloc.dart';
import 'injection_container.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<JobBloc>.value(value: getIt<JobBloc>()),
        BlocProvider<ApplicationBloc>.value(value: getIt<ApplicationBloc>()),
        BlocProvider<MessagesBloc>.value(value: getIt<MessagesBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        // Regista o token FCM assim que há sessão de candidato válida — quer
        // seja logo a seguir ao login, quer ao reabrir a app já autenticado
        // (ver AuthCheckRequested em main.dart).
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            getIt<PushNotificationService>().start();
          }
        },
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Nexora Rec',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF2CB87A)),
            fontFamily: 'Roboto',
          ),
          locale: const Locale('pt'),
          supportedLocales: const [Locale('pt'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/home': (_) => const MainScreen(),
          },
        ),
      ),
    );
  }
}
