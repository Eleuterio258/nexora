import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_shell.dart';
import 'features/admin/presentation/screens/api_keys_screen.dart';
import 'features/admin/presentation/screens/api_calls_screen.dart';
import 'features/admin/presentation/screens/audit_screen.dart';
import 'features/admin/presentation/screens/dashboard_screen.dart';
import 'features/admin/presentation/screens/limits_screen.dart';
import 'features/admin/presentation/screens/merchant_detail_screen.dart';
import 'features/admin/presentation/screens/merchants_screen.dart';
import 'features/admin/presentation/screens/providers_screen.dart';
import 'features/admin/presentation/screens/team_screen.dart';
import 'features/home/pay_home_page.dart';
import 'features/home/screens/carteira_screen.dart';
import 'features/home/screens/enviar_screen.dart';
import 'features/home/screens/facturas_screen.dart';
import 'features/home/screens/historico_screen.dart';
import 'features/home/screens/pagar_screen.dart';
import 'features/home/screens/receber_screen.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const NexoraPayApp());
}

class NexoraPayApp extends StatelessWidget {
  const NexoraPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexora Pay',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'MZ'),
      supportedLocales: const [Locale('pt', 'MZ'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.home: (_) => const PayHomePage(),
        AppRoutes.admin: (_) => const AdminShell(),
        AppRoutes.adminDashboard: (_) => const DashboardScreen(),
        AppRoutes.adminMerchants: (_) => const MerchantsScreen(),
        AppRoutes.adminMerchantDetail: (_) => const MerchantDetailScreen(),
        AppRoutes.adminApiKeys: (_) => const ApiKeysScreen(),
        AppRoutes.adminLimits: (_) => const LimitsScreen(),
        AppRoutes.adminProviders: (_) => const ProvidersScreen(),
        AppRoutes.adminApiCalls: (_) => const ApiCallsScreen(),
        AppRoutes.adminAudit: (_) => const AuditScreen(),
        AppRoutes.adminTeam: (_) => const TeamScreen(),
        AppRoutes.pagar: (_) => const PagarScreen(),
        AppRoutes.receber: (_) => const ReceberScreen(),
        AppRoutes.enviar: (_) => const EnviarScreen(),
        AppRoutes.carteira: (_) => const CarteiraScreen(),
        AppRoutes.facturas: (_) => const FacturasScreen(),
        AppRoutes.historico: (_) => const HistoricoScreen(),
      },
    );
  }
}
