import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexora_school/features/student_portal/domain/entities/student_financeiro_data.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_financeiro_cubit.dart';
import 'package:nexora_school/features/student_portal/presentation/cubit/student_financeiro_state.dart';
import 'package:nexora_school/features/student_portal/presentation/screens/dashboard/sub/comprovativo_screen.dart';

const _green = Color(0xFF00B87A);
const _navy = Color(0xFF0D1B2A);
const _orange = Color(0xFFF59E0B);

class FinanceiroTab extends StatelessWidget {
  const FinanceiroTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(160, 160),
              painter: _BlobPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child:
                      BlocBuilder<
                        StudentFinanceiroCubit,
                        StudentFinanceiroState
                      >(
                        builder: (context, state) => switch (state) {
                          StudentFinanceiroLoading() => const Center(
                            child: CircularProgressIndicator(color: _green),
                          ),
                          StudentFinanceiroError(:final message) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Erro ao carregar: $message',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          StudentFinanceiroLoaded(:final data) => _buildContent(
                            context,
                            data,
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financeiro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Gerencie seus pagamentos',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
          Icon(Icons.help_outline_rounded, size: 26, color: _navy),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, StudentFinanceiroData data) {
    final cobrancas = data.cobrancas;

    final pendentes = cobrancas.where((c) {
      final s = (c['status'] ?? '').toString();
      return s == 'emitida' || s == 'pendente' || s == 'vencida';
    }).toList();

    final pagas = cobrancas.where((c) {
      return (c['status'] ?? '').toString() == 'paga';
    }).toList();

    final totalPago = pagas.fold<double>(
      0,
      (sum, c) => sum + _toDouble(c['valor_total']),
    );
    final totalPendente = pendentes.fold<double>(
      0,
      (sum, c) => sum + _toDouble(c['saldo'] ?? c['valor_total']),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(totalPago, totalPendente, cobrancas.length),
          if (pendentes.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection('Pendente', pendentes, context),
          ],
          if (pagas.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSection('Pago', pagas, context),
          ],
          if (cobrancas.isEmpty) ...[
            const SizedBox(height: 60),
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Color(0xFFCBD5E0),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nenhuma cobrança encontrada',
                    style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Card resumo (estilo perfil) ────────────────────────────────────────────

  Widget _buildSummaryCard(double totalPago, double totalPendente, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: _green,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo Financeiro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ano Lectivo 2026',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _InfoChip(
              icon: Icons.check_circle_outline_rounded,
              label: 'Pago',
              value: _formatMoney(totalPago),
              color: _green,
            ),
            _InfoChip(
              icon: Icons.schedule_rounded,
              label: 'Pendente',
              value: _formatMoney(totalPendente),
              color: totalPendente > 0 ? _orange : _green,
            ),
            _InfoChip(
              icon: Icons.receipt_long_outlined,
              label: 'Total',
              value: '$total cobranças',
              color: _navy,
            ),
          ],
        ),
      ],
    );
  }

  // ── Secção (estilo perfil) ─────────────────────────────────────────────────

  Widget _buildSection(
    String title,
    List<dynamic> items,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return _buildItemRow(
                context,
                entry.value,
                isFirst: entry.key == 0,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Item linha (estilo menu perfil) ───────────────────────────────────────

  Widget _buildItemRow(
    BuildContext context,
    dynamic cobranca, {
    required bool isFirst,
    required bool isLast,
  }) {
    final descricao = (cobranca['descricao'] ?? 'Cobrança').toString();
    final dataVenc = cobranca['data_vencimento']?.toString() ?? '';
    final status = (cobranca['status'] ?? 'pendente').toString();
    final valor = _toDouble(cobranca['valor_total']);
    final saldo = _toDouble(cobranca['saldo'] ?? cobranca['valor_total']);
    final pago = status == 'paga';
    final vencida = status == 'vencida';
    final color = pago ? _green : (vencida ? Colors.redAccent : _orange);

    final pagamento = ComprovativoPagamento(
      referencia: (cobranca['numero'] ?? '').toString(),
      data: dataVenc.isNotEmpty ? _formatDate(dataVenc) : '—',
      metodo: 'M-Pesa',
      numero: (cobranca['id'] ?? '').toString(),
      aluno: '',
      propina: descricao,
      valor: _formatMoney(valor),
    );

    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComprovativoScreen(pagamento: pagamento),
            ),
          ),
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(8) : Radius.zero,
            bottom: isLast ? const Radius.circular(8) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  pago
                      ? Icons.check_circle_rounded
                      : (vencida
                          ? Icons.warning_amber_rounded
                          : Icons.schedule_rounded),
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        descricao,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dataVenc.isNotEmpty
                            ? 'Vencimento: ${_formatDate(dataVenc)}'
                            : 'Vencimento: —',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatMoney(pago ? valor : saldo),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: pago ? _navy : color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E0),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 70,
            endIndent: 16,
            color: Color(0xFFF0F2F5),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static String _formatMoney(double value) =>
      '${value.toStringAsFixed(2).replaceAll('.', ',')} MT';

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Chip de info (igual ao perfil) ────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Blob painter ───────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00B87A).withValues(alpha: 0.06);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.2, 0)
      ..cubicTo(0, 0, 0, size.height * 0.3, size.width * 0.1, size.height * 0.6)
      ..cubicTo(
        size.width * 0.2,
        size.height,
        size.width * 0.7,
        size.height,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
