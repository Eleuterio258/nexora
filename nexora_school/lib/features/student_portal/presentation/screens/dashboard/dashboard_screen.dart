import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/core/di/injection.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_boletim_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_financeiro_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_home_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_mensagens_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_presencas_cubit.dart';
import 'tabs/home_tab.dart';
import 'tabs/agenda_tab.dart';
import 'tabs/boletim_tab.dart';
import 'tabs/chat_tab.dart';
import 'tabs/financeiro_tab.dart';
import 'tabs/perfil_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<StudentHomeCubit>()..load()),
        BlocProvider(create: (_) => sl<StudentBoletimCubit>()..load()),
        BlocProvider(create: (_) => sl<StudentFinanceiroCubit>()..load()),
        BlocProvider(
          create: (_) =>
              sl<StudentPresencasCubit>()..load(mes: _currentMonth()),
        ),
        BlocProvider(create: (_) => sl<StudentMensagensCubit>()..load()),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeTab(),
            AgendaTab(),
            BoletimTab(),
            ChatTab(),
            FinanceiroTab(),
            PerfilTab(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _green = Color(0xFF00B87A);
  static const _grey = Color(0xFF8E8E93);

  static const _items = [
    (icon: Icons.home_rounded, label: 'Início'),
    (icon: Icons.calendar_today_rounded, label: 'Agenda'),
    (icon: Icons.bar_chart_rounded, label: 'Boletim'),
    (icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
    (icon: Icons.account_balance_wallet_outlined, label: 'Financeiro'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == currentIndex;
              final item = _items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (active)
                        Container(
                          width: 40,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else
                        const SizedBox(height: 7),
                      Icon(item.icon, color: active ? _green : _grey, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: active ? _green : _grey,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
