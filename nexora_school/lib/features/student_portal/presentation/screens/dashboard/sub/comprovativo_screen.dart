import 'package:flutter/material.dart';

const _navy = Color(0xFF0D1B2A);
const _green = Color(0xFF00B87A);

class ComprovativoScreen extends StatelessWidget {
  const ComprovativoScreen({super.key, required this.pagamento});

  final ComprovativoPagamento pagamento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _navy,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Comprovativo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _navy,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: _navy, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: _green, size: 22),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          children: [
            // ── Recibo estilo PDF ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Cabeçalho verde
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00A36C), Color(0xFF00C98A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Logo placeholder — N estilizado
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'N',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nexora School',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Sistema Escolar Digital',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Selo de confirmação
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Column(
                      children: [
                        Text(
                          'Pagamento Confirmado',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pagamento.valor,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _green,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divisor tipo recibo
                        _TicketDivider(),
                        const SizedBox(height: 16),

                        // Linhas de detalhe
                        _InfoLinha(
                          icon: Icons.receipt_outlined,
                          label: 'Referência',
                          value: pagamento.referencia,
                        ),
                        _InfoLinha(
                          icon: Icons.calendar_today_outlined,
                          label: 'Data de pagamento',
                          value: pagamento.data,
                        ),
                        _InfoLinha(
                          icon: Icons.phone_android_rounded,
                          label: 'Método',
                          value: pagamento.metodo,
                        ),
                        _InfoLinha(
                          icon: Icons.numbers_rounded,
                          label: 'Número',
                          value: pagamento.numero,
                        ),
                        _InfoLinha(
                          icon: Icons.school_outlined,
                          label: 'Escola',
                          value: 'Nexora School',
                        ),
                        _InfoLinha(
                          icon: Icons.person_outline_rounded,
                          label: 'Aluno',
                          value: pagamento.aluno,
                        ),
                        _InfoLinha(
                          icon: Icons.credit_card_outlined,
                          label: 'Propina',
                          value: pagamento.propina,
                        ),
                        _InfoLinha(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Estado',
                          value: 'PAGO',
                          valueColor: _green,
                          valueBold: true,
                        ),

                        const SizedBox(height: 16),
                        _TicketDivider(),
                        const SizedBox(height: 16),

                        // Rodapé do recibo
                        Text(
                          'Este comprovativo é válido como prova de pagamento.\nGuarde-o para os seus registos.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'REF: ${pagamento.referencia}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFADB5BD),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Botões
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text(
                  'Baixar PDF',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text(
                  'Partilhar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Divisor tipo ticket (tracejado) ───────────────────────────────────────────

class _TicketDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        30,
        (i) => Expanded(
          child: Container(
            height: 1.5,
            color: i.isEven ? const Color(0xFFE5E7EB) : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

// ── Linha de informação ────────────────────────────────────────────────────────

class _InfoLinha extends StatelessWidget {
  const _InfoLinha({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFADB5BD)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? _navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelo de dados ────────────────────────────────────────────────────────────

class ComprovativoPagamento {
  const ComprovativoPagamento({
    required this.referencia,
    required this.data,
    required this.metodo,
    required this.numero,
    required this.aluno,
    required this.propina,
    required this.valor,
  });

  final String referencia, data, metodo, numero, aluno, propina, valor;
}
