import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/student_portal/domain/entities/student_financeiro_data.dart';
import '../../../../features/student_portal/presentation/cubit/student_financeiro_cubit.dart';
import '../../../../features/student_portal/presentation/cubit/student_financeiro_state.dart';
import '../sub/comprovativo_screen.dart';

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
                        builder: (context, state) {
                          return switch (state) {
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
                            StudentFinanceiroLoaded(:final data) =>
                              _buildContent(context, data),
                            _ => const SizedBox.shrink(),
                          };
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

  Widget _buildContent(BuildContext context, StudentFinanceiroData data) {
    final pendente = data.cobrancas.where((c) {
      final status = (c['status'] ?? '').toString();
      return status == 'emitida' || status == 'pendente' || status == 'vencida';
    }).toList();

    final proximo = pendente.isNotEmpty ? pendente.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (proximo != null) _buildProximoVencimento(proximo),
          const SizedBox(height: 28),
          _buildHistoricoHeader(data.cobrancas.length),
          const SizedBox(height: 12),
          ...data.cobrancas.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPagamentoCard(context, p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProximoVencimento(dynamic cobranca) {
    final descricao = (cobranca['descricao'] ?? 'Propina').toString();
    final dataVenc = cobranca['data_vencimento'] ?? '';
    final valor = _toDouble(cobranca['saldo'] ?? cobranca['valor_total']);
    final valorStr = _formatMoney(valor);
    final dia = dataVenc.toString().isNotEmpty
        ? dataVenc.toString().split('-')[2]
        : '--';
    final mes = dataVenc.toString().isNotEmpty
        ? _monthName(int.tryParse(dataVenc.toString().split('-')[1]) ?? 1)
        : '---';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A36C), Color(0xFF00C98A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRÓXIMO VENCIMENTO',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$dia/$mes',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 56, color: Colors.white24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VALOR',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              valorStr,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoHeader(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Histórico',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        Text(
          '$total cobranças',
          style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
        ),
      ],
    );
  }

  Widget _buildPagamentoCard(BuildContext context, dynamic cobranca) {
    final descricao = (cobranca['descricao'] ?? 'Cobrança').toString();
    final dataVenc = cobranca['data_vencimento'] ?? '';
    final status = (cobranca['status'] ?? 'pendente').toString();
    final valor = _toDouble(cobranca['valor_total']);
    final pago = status == 'paga';
    final color = pago
        ? _green
        : (status == 'vencida' ? Colors.redAccent : _orange);

    final pagamento = ComprovativoPagamento(
      referencia: (cobranca['numero'] ?? '').toString(),
      data: dataVenc.toString().isNotEmpty
          ? _formatDate(dataVenc.toString())
          : '—',
      metodo: 'M-Pesa',
      numero: (cobranca['id'] ?? '').toString(),
      aluno: '',
      propina: descricao,
      valor: _formatMoney(valor),
    );

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprovativoScreen(pagamento: pagamento),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                pago ? Icons.check_circle_rounded : Icons.schedule_rounded,
                color: color,
                size: 24,
              ),
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
                    dataVenc.toString().isNotEmpty
                        ? 'Vencimento: ${_formatDate(dataVenc.toString())}'
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
                  _formatMoney(valor),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: pago ? _navy : color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static String _formatMoney(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} MT';
  }

  static String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _monthName(int month) {
    const names = [
      '',
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];
    return names[month];
  }
}

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
