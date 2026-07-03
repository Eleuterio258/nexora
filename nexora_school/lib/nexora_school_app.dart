import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/constants/app_routes.dart';
import 'package:nexora_school/core/di/injection.dart';
import 'package:nexora_school/features/agenda/presentation/bloc/agenda_bloc.dart';
import 'package:nexora_school/features/agenda/presentation/bloc/agenda_event.dart';
import 'package:nexora_school/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nexora_school/features/onboarding/onboarding_screen.dart';
import 'package:nexora_school/features/splash/splash_screen.dart';
import 'package:nexora_school/screens/auth/login_screen.dart';

// Aluno
import 'package:nexora_school/screens/aluno/dashboard/dashboard_screen.dart';
import 'package:nexora_school/screens/aluno/dashboard/sub/calendario_screen.dart';
import 'package:nexora_school/screens/aluno/dashboard/sub/chat_screen.dart';
import 'package:nexora_school/screens/aluno/dashboard/sub/noticias_screen.dart';
import 'package:nexora_school/screens/aluno/dashboard/sub/notificacoes_screen.dart'
    as notif;
import 'package:nexora_school/screens/aluno/dashboard/sub/turma_screen.dart';
import 'package:nexora_school/screens/aluno/frequencia/faltas_screen.dart';
import 'package:nexora_school/screens/aluno/frequencia/frequencia_screen.dart';
import 'package:nexora_school/screens/aluno/perfil/ajuda_faq_screen.dart';
import 'package:nexora_school/screens/aluno/perfil/editar_perfil_screen.dart';
import 'package:nexora_school/screens/aluno/perfil/notificacoes_screen.dart'
    as notif_settings;
import 'package:nexora_school/screens/aluno/perfil/seguranca_screen.dart';

// Teacher
import 'package:nexora_school/screens/teacher/attendance_screen.dart';
import 'package:nexora_school/screens/teacher/class_detail_teacher_screen.dart';
import 'package:nexora_school/screens/teacher/class_list_screen.dart';
import 'package:nexora_school/screens/teacher/class_report_screen.dart';
import 'package:nexora_school/screens/teacher/create_announcement_screen.dart';
import 'package:nexora_school/screens/teacher/create_task_screen.dart';
import 'package:nexora_school/screens/teacher/grade_entry_class_screen.dart';
import 'package:nexora_school/screens/teacher/grade_entry_students_screen.dart';
import 'package:nexora_school/screens/teacher/teacher_dashboard_screen.dart';

class NexoraSchoolApp extends StatelessWidget {
  const NexoraSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<AgendaBloc>()..add(AgendaStarted())),
      ],
      child: MaterialApp(
        title: 'Nexora School',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00B87A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00B87A),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0D1B2A),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.dashboard: (_) => const DashboardScreen(),

          // Aluno
          AppRoutes.notifications: (_) => const notif.NotificacoesScreen(),
          AppRoutes.calendar: (_) => const CalendarioScreen(),
          AppRoutes.messages: (_) =>
              const ChatScreen(nome: 'Conversa', sub: ''),
          AppRoutes.classDetail: (_) => const TurmaScreen(),
          AppRoutes.studentAttendance: (_) => const FrequenciaScreen(),
          AppRoutes.justifyAbsence: (_) => const FaltasScreen(),
          AppRoutes.editProfile: (_) => const EditarPerfilScreen(),
          AppRoutes.changePassword: (_) => const SegurancaScreen(),
          AppRoutes.helpFaq: (_) => const AjudaFaqScreen(),
          AppRoutes.settingsMenu: (_) =>
              const notif_settings.NotificacoesScreen(),
          AppRoutes.announcementDetail: (_) => const NoticiasScreen(),

          // Teacher
          AppRoutes.teacherDashboard: (_) => const TeacherDashboardScreen(),
          AppRoutes.classList: (_) => const ClassListScreen(),
          AppRoutes.gradeEntryClass: (_) => const GradeEntryClassScreen(),
          AppRoutes.gradeEntryStudents: (_) => const GradeEntryStudentsScreen(),
          AppRoutes.attendance: (_) => const AttendanceScreen(),
          AppRoutes.classDetailTeacher: (_) => const ClassDetailTeacherScreen(
            turma: '10ª Classe A',
            disciplina: 'Matemática',
          ),
          AppRoutes.createTask: (_) => const CreateTaskScreen(),
          AppRoutes.createAnnouncement: (_) => const CreateAnnouncementScreen(),
          AppRoutes.classReport: (_) => const ClassReportScreen(),
        },
      ),
    );
  }
}
