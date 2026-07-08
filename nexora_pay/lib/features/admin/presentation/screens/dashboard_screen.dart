import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/mock_admin_repository.dart';
import '../blocs/dashboard/dashboard_cubit.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(MockAdminRepository())..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().load(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return switch (state) {
            DashboardLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            DashboardError(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<DashboardCubit>().load(),
              ),
            DashboardLoaded(:final summary) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStats(context, summary),
                  const SizedBox(height: 24),
                  const SectionHeader('Atividade recente'),
                  _buildActivityList(summary.recentActivity),
                ],
              ),
          };
        },
      ),
    );
  }

  Widget _buildStats(BuildContext context, DashboardSummary summary) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _buildStatCards(context, summary),
    );
  }

  List<Widget> _buildStatCards(BuildContext context, DashboardSummary summary) {
    return [
        StatCard(
          label: 'Transações hoje',
          value: summary.transactionsToday,
          icon: Icons.swap_horiz,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminApiCalls),
        ),
        StatCard(
          label: 'Volume hoje',
          value: summary.totalVolumeToday,
          icon: Icons.payments,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminApiCalls),
        ),
        StatCard(
          label: 'Comerciantes ativos',
          value: summary.activeMerchants,
          icon: Icons.storefront,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminMerchants),
        ),
        StatCard(
          label: 'Erros',
          value: summary.totalErrors,
          icon: Icons.error_outline,
          color: AppColors.error,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminApiCalls),
        ),
      ];
  }

  Widget _buildActivityList(List<DashboardActivity> activities) {
    if (activities.isEmpty) {
      return const EmptyState(message: 'Sem atividade recente');
    }

    return Card(
      child: Column(
        children: activities.map((activity) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.notifications_none),
            ),
            title: Text(activity.title),
            subtitle: Text(activity.subtitle),
            trailing: Text(
              DateFormat.Hm().format(activity.timestamp),
              style: const TextStyle(color: AppColors.grey),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
