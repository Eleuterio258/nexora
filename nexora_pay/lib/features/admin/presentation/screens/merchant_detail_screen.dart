import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/merchant.dart';
import '../widgets/status_badge.dart';

class MerchantDetailScreen extends StatelessWidget {
  const MerchantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final merchant = ModalRoute.of(context)!.settings.arguments as Merchant;
    final theme = Theme.of(context);
    final (badgeType, badgeLabel) = switch (merchant.status) {
      MerchantStatus.active => (StatusBadgeType.success, merchant.statusLabel),
      MerchantStatus.pending => (StatusBadgeType.warning, merchant.statusLabel),
      MerchantStatus.suspended => (StatusBadgeType.error, merchant.statusLabel),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do comerciante'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primary,
                        radius: 28,
                        child: Text(
                          merchant.name[0],
                          style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchant.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            StatusBadge(label: badgeLabel, status: badgeType),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InfoRow(label: 'Email', value: merchant.email),
                  _InfoRow(label: 'Telefone', value: merchant.phone),
                  _InfoRow(label: 'NIF', value: merchant.nif ?? 'Não indicado'),
                  _InfoRow(
                    label: 'Endereço',
                    value: merchant.address ?? 'Não indicado',
                  ),
                  _InfoRow(
                    label: 'Data de criação',
                    value: DateFormat('dd/MM/yyyy').format(merchant.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key, color: AppColors.primary),
                  title: const Text('Chaves de acesso'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/admin/keys'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.speed, color: AppColors.primary),
                  title: const Text('Limites e políticas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/admin/limits'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history, color: AppColors.primary),
                  title: const Text('Histórico de chamadas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed('/admin/calls'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
