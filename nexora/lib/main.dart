import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/services/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<SessionManager>.value(
      value: sl<SessionManager>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => sl<AuthBloc>()..add(AppStarted()),
          ),
          BlocProvider<AttendanceBloc>(create: (_) => sl<AttendanceBloc>()),
        ],
        child: MaterialApp(
          title: 'Nexora',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const SplashPage(),
        ),
      ),
    );
  }
}
