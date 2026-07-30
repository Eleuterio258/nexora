import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pedido_ferias_entity.dart';
import '../../domain/entities/pedido_ferias_status.dart';

class PedidoFeriasTile extends StatelessWidget {
  final PedidoFeriasEntity pedido;
  final VoidCallback? onCancelar;

  const PedidoFeriasTile({super.key, required this.pedido, this.onCancelar});

  Color get _statusColor {
    switch (pedido.estado) {
      case PedidoFeriasStatus.pendente:
        return AppColors.amber;
      case PedidoFeriasStatus.aprovado:
        return AppColors.green;
      case PedidoFeriasStatus.gozada:
        return AppColors.blue;
      case PedidoFeriasStatus.rejeitado:
        return AppColors.red;
      case PedidoFeriasStatus.cancelado:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (pedido.estado) {
      case PedidoFeriasStatus.pendente:
        return 'Pendente';
      case PedidoFeriasStatus.aprovado:
        return 'Aprovado';
      case PedidoFeriasStatus.gozada:
        return 'Gozada';
      case PedidoFeriasStatus.rejeitado:
        return 'Rejeitado';
      case PedidoFeriasStatus.cancelado:
        return 'Cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pedido.tipoNome ?? 'Ausência',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${formatter.format(pedido.dataInicio)} — ${formatter.format(pedido.dataFim)}'
              '${pedido.dias != null ? ' (${pedido.dias} dia${pedido.dias == 1 ? '' : 's'})' : ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            if (pedido.motivo != null && pedido.motivo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                pedido.motivo!,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
            if (pedido.estado == PedidoFeriasStatus.pendente && onCancelar != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancelar,
                  style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  child: const Text('Cancelar pedido'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
