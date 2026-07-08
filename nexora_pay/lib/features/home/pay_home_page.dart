import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import 'widgets/balance_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/section_title.dart';
import 'widgets/transaction_tile.dart';

class PayHomePage extends StatelessWidget {
  const PayHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexora Pay'),
        actions: [
          IconButton(
            tooltip: 'Painel administrativo',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.admin),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
          IconButton(
            tooltip: 'Notificacoes',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            BalanceCard(),
            SizedBox(height: 24),
            SectionTitle('Acoes rapidas'),
            SizedBox(height: 12),
            QuickActions(),
            SizedBox(height: 24),
            SectionTitle('Movimentos recentes'),
            SizedBox(height: 12),
            TransactionTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Pagamento POS',
              subtitle: 'Hoje, 14:20',
              amount: '-850,00 MT',
            ),
            TransactionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Carregamento',
              subtitle: 'Hoje, 09:15',
              amount: '+5.000,00 MT',
              positive: true,
            ),
            TransactionTile(
              icon: Icons.receipt_long_outlined,
              title: 'Factura Nexora',
              subtitle: 'Ontem, 16:45',
              amount: '-1.250,00 MT',
            ),
          ],
        ),
      ),
    );
  }
}
