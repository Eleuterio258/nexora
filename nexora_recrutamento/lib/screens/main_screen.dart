import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';
import 'dashboard_screen.dart';
import 'jobs_screen.dart';
import 'applications_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static final _pages = <Widget>[
    const DashboardScreen(),
    const JobsScreen(),
    const ApplicationsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          selectedItemColor: kPrimary,
          unselectedItemColor: const Color(0xFF9AA5B1),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              activeIcon: Icon(Icons.home, size: 26),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline, size: 26),
              activeIcon: Icon(Icons.work, size: 26),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined, size: 26),
              activeIcon: Icon(Icons.description, size: 26),
              label: 'Applications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 26),
              activeIcon: Icon(Icons.chat_bubble, size: 26),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 26),
              activeIcon: Icon(Icons.person, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
