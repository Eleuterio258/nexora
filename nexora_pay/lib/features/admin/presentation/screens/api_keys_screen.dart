import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/api_key.dart';

import '../../data/repositories/mock_admin_repository.dart';
import '../blocs/api_keys/api_keys_cubit.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

class ApiKeysScreen extends StatelessWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApiKeysCubit(MockAdminRepository())..load(),
      child: const _ApiKeysView(),
    );
  }
}

class _ApiKeysView extends StatelessWidget {
  const _ApiKeysView();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<ApiKeysCubit>().load(),
      child: BlocConsumer<ApiKeysCubit, ApiKeysState>(
        listener: _handleNewKey,
        builder: (context, state) {
          return switch (state) {
            ApiKeysLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ApiKeysError(:final message) => ErrorState(
                message: message,
                onRetry: () => context.read<ApiKeysCubit>().load(),
              ),
            ApiKeysLoaded(:final keys) => keys.isEmpty
                ? const EmptyState(message: 'Nenhuma chave registada')
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildGenerateButton(context),
                      const SizedBox(height: 16),
                      const SectionHeader('Chaves de acesso'),
                      ...keys.map((key) => _ApiKeyCard(key)),
                    ],
                  ),
          };
        },
      ),
    );
  }

  void _handleNewKey(BuildContext context, ApiKeysState state) {
    if (state is ApiKeysLoaded && state.newlyCreated?.value != null) {
      _showKeyDialog(context, state.newlyCreated!);
      context.read<ApiKeysCubit>().clearNewlyCreated();
    }
  }

  Widget _buildGenerateButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => _showGenerateDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Gerar nova chave'),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    String merchantId = 'm1';
    ApiKeyType type = ApiKeyType.public;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Gerar chave'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: merchantId,
                    decoration: const InputDecoration(labelText: 'Comerciante'),
                    items: const [
                      DropdownMenuItem(value: 'm1', child: Text('Loja Virtual Exemplo')),
                      DropdownMenuItem(value: 'm2', child: Text('Supermercado Bom Preço')),
                    ],
                    onChanged: (value) => setState(() => merchantId = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ApiKeyType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: ApiKeyType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => type = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.read<ApiKeysCubit>().generateKey(
                          merchantId: merchantId,
                          type: type,
                        );
                  },
                  child: const Text('Gerar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showKeyDialog(BuildContext context, ApiKey key) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Chave gerada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Guarde esta chave num local seguro. Só será mostrada uma vez.',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              SelectableText(
                key.value!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: key.value!));
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar'),
            ),
          ],
        );
      },
    );
  }
}

class _ApiKeyCard extends StatelessWidget {
  const _ApiKeyCard(this.apiKey);

  final ApiKey apiKey;

  @override
  Widget build(BuildContext context) {
    final (badgeType, badgeLabel) = switch (apiKey.status) {
      ApiKeyStatus.active => (StatusBadgeType.success, apiKey.statusLabel),
      ApiKeyStatus.revoked => (StatusBadgeType.error, apiKey.statusLabel),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Icon(apiKey.type == ApiKeyType.public ? Icons.public : Icons.lock),
        ),
        title: Text(apiKey.merchantName),
        subtitle: Text('${apiKey.typeLabel} • ${apiKey.prefix}\nÚltimo uso: ${_formatLastUse()}'),
        isThreeLine: true,
        trailing: StatusBadge(label: badgeLabel, status: badgeType),
        onTap: apiKey.status == ApiKeyStatus.active
            ? () => _confirmRevoke(context)
            : null,
      ),
    );
  }

  String _formatLastUse() {
    if (apiKey.lastUsedAt == null) return 'Nunca';
    return '${apiKey.lastUsedAt!.day}/${apiKey.lastUsedAt!.month} ${apiKey.lastUsedAt!.hour}:${apiKey.lastUsedAt!.minute.toString().padLeft(2, '0')}';
  }

  void _confirmRevoke(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revogar chave'),
        content: const Text('Tem a certeza? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ApiKeysCubit>().revoke(apiKey.id);
            },
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
  }
}
