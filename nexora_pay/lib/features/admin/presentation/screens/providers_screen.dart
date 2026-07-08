import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/provider.dart';
import '../../data/repositories/mock_admin_repository.dart';
import '../blocs/providers/providers_cubit.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProvidersCubit(MockAdminRepository())..load(),
      child: const _ProvidersView(),
    );
  }
}

class _ProvidersView extends StatelessWidget {
  const _ProvidersView();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<ProvidersCubit>().load(),
      child: BlocBuilder<ProvidersCubit, ProvidersState>(
        builder: (context, state) {
          return switch (state) {
            ProvidersLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ProvidersError(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<ProvidersCubit>().load(),
              ),
            ProvidersLoaded(:final providers) => providers.isEmpty
                ? const EmptyState(message: 'Nenhum provedor configurado')
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SectionHeader('Provedores de pagamento'),
                      ...providers.map((provider) => _ProviderCard(provider)),
                    ],
                  ),
          };
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard(this.provider);

  final PaymentProvider provider;

  @override
  Widget build(BuildContext context) {
    final (badgeType, _) = switch (provider.status) {
      ProviderStatus.active => (StatusBadgeType.success, provider.statusLabel),
      ProviderStatus.inactive => (StatusBadgeType.neutral, provider.statusLabel),
      ProviderStatus.maintenance => (StatusBadgeType.warning, provider.statusLabel),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.payment),
        ),
        title: Text(provider.name),
        subtitle: Text(provider.description ?? ''),
        trailing: StatusBadge(
          label: provider.statusLabel,
          status: badgeType,
        ),
        onTap: () => context.read<ProvidersCubit>().toggleStatus(provider.id),
      ),
    );
  }
}
