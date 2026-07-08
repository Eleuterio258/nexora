import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/merchant.dart';
import '../../data/repositories/mock_admin_repository.dart';
import '../blocs/merchants/merchants_cubit.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

class MerchantsScreen extends StatelessWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MerchantsCubit(MockAdminRepository())..load(),
      child: const _MerchantsView(),
    );
  }
}

class _MerchantsView extends StatefulWidget {
  const _MerchantsView();

  @override
  State<_MerchantsView> createState() => _MerchantsViewState();
}

class _MerchantsViewState extends State<_MerchantsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<MerchantsCubit>().load(),
      child: BlocBuilder<MerchantsCubit, MerchantsState>(
        builder: (context, state) {
          return switch (state) {
            MerchantsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            MerchantsError(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<MerchantsCubit>().load(),
              ),
            MerchantsLoaded(:final visible) => visible.isEmpty
                ? const EmptyState(message: 'Nenhum comerciante encontrado')
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSearch(context),
                      const SizedBox(height: 16),
                      const SectionHeader('Comerciantes'),
                      ...visible.map((merchant) => _MerchantCard(merchant)),
                    ],
                  ),
          };
        },
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Pesquisar comerciante...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) => context.read<MerchantsCubit>().filter(value),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard(this.merchant);

  final Merchant merchant;

  @override
  Widget build(BuildContext context) {
    final (badgeType, badgeLabel) = switch (merchant.status) {
      MerchantStatus.active => (StatusBadgeType.success, merchant.statusLabel),
      MerchantStatus.pending => (StatusBadgeType.warning, merchant.statusLabel),
      MerchantStatus.suspended => (StatusBadgeType.error, merchant.statusLabel),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Text(merchant.name[0]),
        ),
        title: Text(merchant.name),
        subtitle: Text('${merchant.email}\n${merchant.phone}'),
        isThreeLine: true,
        trailing: StatusBadge(label: badgeLabel, status: badgeType),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.adminMerchantDetail,
          arguments: merchant,
        ),
        onLongPress: () => _showActions(context),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Aprovar / Ativar'),
                leading: const Icon(Icons.check_circle, color: AppColors.success),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<MerchantsCubit>()
                      .updateStatus(merchant.id, MerchantStatus.active);
                },
              ),
              ListTile(
                title: const Text('Suspender'),
                leading: const Icon(Icons.block, color: AppColors.error),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<MerchantsCubit>()
                      .updateStatus(merchant.id, MerchantStatus.suspended);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
