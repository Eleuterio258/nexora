import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import 'presentation/screens/api_keys_screen.dart';
import 'presentation/screens/audit_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/merchants_screen.dart';
import 'presentation/screens/providers_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      screen: DashboardScreen(),
    ),
    _NavItem(
      label: 'Comerciantes',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      screen: MerchantsScreen(),
    ),
    _NavItem(
      label: 'Chaves',
      icon: Icons.key_outlined,
      selectedIcon: Icons.key,
      screen: ApiKeysScreen(),
    ),
    _NavItem(
      label: 'Provedores',
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance,
      screen: ProvidersScreen(),
    ),
    _NavItem(
      label: 'Auditoria',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      screen: AuditScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_selectedIndex].label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu administrativo',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const _AdminDrawer(),
      body: SafeArea(
        child: _destinations[_selectedIndex].screen,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: _destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Nexora Pay Admin',
                style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const Divider(),
            _DrawerTile(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              route: AppRoutes.adminDashboard,
              currentRoute: currentRoute,
            ),
            _DrawerTile(
              icon: Icons.storefront_outlined,
              label: 'Comerciantes',
              route: AppRoutes.adminMerchants,
              currentRoute: currentRoute,
            ),
            _DrawerTile(
              icon: Icons.key_outlined,
              label: 'Chaves de acesso',
              route: AppRoutes.adminApiKeys,
              currentRoute: currentRoute,
            ),
            _DrawerTile(
              icon: Icons.speed_outlined,
              label: 'Limites e políticas',
              route: AppRoutes.adminLimits,
              currentRoute: currentRoute,
            ),
            _DrawerTile(
              icon: Icons.account_balance_outlined,
              label: 'Provedores',
              route: AppRoutes.adminProviders,
              currentRoute: currentRoute,
            ),
            _DrawerTile(
              icon: Icons.history_outlined,
              label: 'Logs de chamadas',
              route: AppRoutes.adminApiCalls,
              currentRoute: currentRoute,
            ),
            _DrawerTile(
              icon: Icons.assignment_outlined,
              label: 'Auditoria',
              route: AppRoutes.adminAudit,
              currentRoute: currentRoute,
            ),
            _DrawerTile(
              icon: Icons.people_outlined,
              label: 'Equipa',
              route: AppRoutes.adminTeam,
              currentRoute: currentRoute,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  final IconData icon;
  final String label;
  final String route;
  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop();
        if (!isSelected) {
          Navigator.of(context).pushNamed(route);
        }
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
