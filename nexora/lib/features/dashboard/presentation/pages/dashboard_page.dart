import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/session_manager.dart';
import '../../../attendance/presentation/pages/attendance_history_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../ferias/presentation/pages/ferias_page.dart';
import 'home_page.dart';
import 'modulos_page.dart';
import 'perfil_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  static const _titles = ['Início', 'Módulos', 'Chat', 'Férias', 'Assiduidade', 'Perfil'];

  void _logout(BuildContext context) {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.read<SessionManager>();
    final user = sessionManager.user;
    final modules = sessionManager.modules;

    final pages = [
      HomePage(user: user, onLogout: () => _logout(context)),
      ModulosPage(modules: modules),
      const ChatPage(),
      const FeriasPage(),
      const AttendanceHistoryPage(),
      PerfilPage(user: user, onLogout: () => _logout(context)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Módulos',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Férias',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Assiduidade',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
