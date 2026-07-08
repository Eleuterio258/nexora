import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/mock_admin_repository.dart';
import '../blocs/audit/audit_cubit.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_header.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuditCubit(MockAdminRepository())..load(),
      child: const _AuditView(),
    );
  }
}

class _AuditView extends StatefulWidget {
  const _AuditView();

  @override
  State<_AuditView> createState() => _AuditViewState();
}

class _AuditViewState extends State<_AuditView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<AuditCubit>().load(),
      child: BlocBuilder<AuditCubit, AuditState>(
        builder: (context, state) {
          return switch (state) {
            AuditLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            AuditError(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<AuditCubit>().load(),
              ),
            AuditLoaded(:final visible) => visible.isEmpty
                ? const EmptyState(message: 'Nenhum registo encontrado')
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSearch(context),
                      const SizedBox(height: 16),
                      const SectionHeader('Registo de auditoria'),
                      ...visible.map((log) => _AuditLogCard(log)),
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
        hintText: 'Pesquisar por utilizador ou ação...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) => context.read<AuditCubit>().filter(value),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard(this.log);

  final dynamic log;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  log.action,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                ),
                Text(
                  DateFormat('dd/MM HH:mm').format(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              log.userName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text('Alvo: ${log.target}'),
            const SizedBox(height: 4),
            Text(
              log.details,
              style: const TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
