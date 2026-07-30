import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/conversa_entity.dart';

class ConversaTile extends StatelessWidget {
  final ConversaEntity conversa;
  final VoidCallback onTap;

  const ConversaTile({super.key, required this.conversa, required this.onTap});

  String _formatData(DateTime data) {
    final now = DateTime.now();
    final isHoje = data.year == now.year && data.month == now.month && data.day == now.day;
    return isHoje ? DateFormat('HH:mm').format(data) : DateFormat('dd/MM').format(data);
  }

  @override
  Widget build(BuildContext context) {
    final temNaoLidas = conversa.naoLidas > 0;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.brandAccent.withValues(alpha: 0.15),
        child: Text(
          conversa.nomeExibicao.isNotEmpty
              ? conversa.nomeExibicao[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: AppColors.brandAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        conversa.nomeExibicao,
        style: TextStyle(
          fontWeight: temNaoLidas ? FontWeight.bold : FontWeight.normal,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        conversa.ultimaMensagem ?? 'Sem mensagens ainda',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: temNaoLidas ? AppColors.textPrimary : AppColors.textMuted,
          fontWeight: temNaoLidas ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversa.ultimaData != null)
            Text(
              _formatData(conversa.ultimaData!),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          if (temNaoLidas) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversa.naoLidas}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
