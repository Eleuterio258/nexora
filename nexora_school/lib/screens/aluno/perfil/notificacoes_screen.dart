import 'package:flutter/material.dart';

const _green = Color(0xFF00B87A);
const _navy  = Color(0xFF0D1B2A);

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  final _prefs = {
    'Notas e boletim':       true,
    'Pagamentos e propinas':  true,
    'Comunicados da escola':  true,
    'Agenda e horários':     true,
    'Faltas e presenças':    false,
    'Eventos escolares':     true,
    'Mensagens de professores': false,
  };

  final _icons = {
    'Notas e boletim':         Icons.bar_chart_rounded,
    'Pagamentos e propinas':   Icons.account_balance_wallet_outlined,
    'Comunicados da escola':   Icons.campaign_outlined,
    'Agenda e horários':       Icons.calendar_today_rounded,
    'Faltas e presenças':      Icons.how_to_reg_outlined,
    'Eventos escolares':       Icons.event_outlined,
    'Mensagens de professores': Icons.chat_bubble_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notificações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 4),
          const Text('Escolha que tipos de notificações deseja receber.',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _prefs.entries.map((e) {
                final isLast = e.key == _prefs.keys.last;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_icons[e.key], color: _green, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(e.key,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500, color: _navy)),
                          ),
                          Switch.adaptive(
                            value: e.value,
                            onChanged: (v) => setState(() => _prefs[e.key] = v),
                            activeTrackColor: _green,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 68, endIndent: 16,
                          color: Color(0xFFF0F2F5)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
