import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../attendance/presentation/pages/facial_attendance_page.dart';
import '../../../attendance/presentation/pages/fingerprint_attendance_page.dart';
import '../../../attendance/presentation/pages/nfc_attendance_page.dart';
import '../../../attendance/presentation/pages/pin_attendance_page.dart';
import '../../../attendance/presentation/pages/qr_attendance_page.dart';
import '../../../attendance/presentation/pages/selfie_gps_attendance_page.dart';
import '../../../attendance/presentation/widgets/attendance_method_card.dart';
import '../../../auth/data/models/user_model.dart';
import '../widgets/assiduidade_card.dart';
import '../widgets/empty_state_text.dart';
import '../widgets/saldo_ferias_card.dart';
import '../widgets/section_header.dart';

class _MetodoRegisto {
  final IconData icon;
  final String label;

  const _MetodoRegisto(this.icon, this.label);
}

const _metodosRegisto = [
  _MetodoRegisto(Icons.qr_code, 'QR Code'),
  _MetodoRegisto(Icons.face_outlined, 'Facial'),
  _MetodoRegisto(Icons.location_on_outlined, 'Selfie + GPS'),
  _MetodoRegisto(Icons.lock_outline, 'PIN'),
  _MetodoRegisto(Icons.nfc, 'NFC'),
  _MetodoRegisto(Icons.fingerprint, 'Impressão Digital'),
];

const _diaSemanaLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

class HomePage extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const HomePage({super.key, required this.user, required this.onLogout});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label em breve')),
    );
  }

  void _openAttendanceMethod(BuildContext context, String label) {
    final page = switch (label) {
      'QR Code' => const QrAttendancePage(),
      'Facial' => const FacialAttendancePage(),
      'Selfie + GPS' => const SelfieGpsAttendancePage(),
      'PIN' => const PinAttendancePage(),
      'NFC' => const NfcAttendancePage(),
      'Impressão Digital' => const FingerprintAttendancePage(),
      _ => null,
    };

    if (page != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    } else {
      _comingSoon(context, label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(userName: user?.name, onLogout: onLogout),
        const SizedBox(height: 16),
        _RegistarPresencaSection(
          onSelecionarMetodo: (label) => _openAttendanceMethod(context, label),
        ),
        const SizedBox(height: 20),
        const _ResumoCards(),
        const SizedBox(height: 16),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),
        _EventosSection(onVerTodos: () => _comingSoon(context, 'Eventos')),
        const SizedBox(height: 16),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),
        _EmptySection(
          title: 'Notificações',
          message: 'Sem notificações',
          onVerTodos: () => _comingSoon(context, 'Notificações'),
        ),
        const SizedBox(height: 14),
        _EmptySection(
          title: 'Comunicados Recentes',
          message: 'Sem comunicados recentes',
          onVerTodos: () => _comingSoon(context, 'Comunicados'),
        ),
        const SizedBox(height: 14),
        _EmptySection(
          title: 'Aniversários',
          message: 'Sem aniversários esta semana',
          onVerTodos: () => _comingSoon(context, 'Aniversários'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String? userName;
  final VoidCallback onLogout;

  const _Header({required this.userName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${userName ?? 'Utilizador'}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aqui está o teu resumo de hoje',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onLogout,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            side: const BorderSide(color: AppColors.borderStrong),
            foregroundColor: AppColors.brandAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            minimumSize: Size.zero,
            textStyle: const TextStyle(fontSize: 13),
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class _RegistarPresencaSection extends StatelessWidget {
  final ValueChanged<String> onSelecionarMetodo;

  const _RegistarPresencaSection({required this.onSelecionarMetodo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registar Presença',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Escolha o método de registro',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _metodosRegisto.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final metodo = _metodosRegisto[index];
              return AttendanceMethodCard(
                icon: metodo.icon,
                label: metodo.label,
                onTap: () => onSelecionarMetodo(metodo.label),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResumoCards extends StatelessWidget {
  const _ResumoCards();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            child: SaldoFeriasCard(dias: '—', total: 'sem dados'),
          ),
          SizedBox(width: 12),
          VerticalDivider(color: AppColors.border, width: 1),
          SizedBox(width: 12),
          Expanded(
            child: AssiduidadeCard(diasTrabalhados: '—', horas: 'sem dados'),
          ),
        ],
      ),
    );
  }
}

class _EventosSection extends StatelessWidget {
  final VoidCallback onVerTodos;

  const _EventosSection({required this.onVerTodos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Eventos', onVerTodos: onVerTodos),
        const SizedBox(height: 12),
        const _WeekCalendarRow(),
        const SizedBox(height: 14),
        const EmptyStateText('Sem eventos agendados esta semana'),
      ],
    );
  }
}

class _WeekCalendarRow extends StatelessWidget {
  const _WeekCalendarRow();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    return Row(
      children: List.generate(7, (index) {
        final dia = monday.add(Duration(days: index));
        final isHoje = dia.year == now.year &&
            dia.month == now.month &&
            dia.day == now.day;
        return Expanded(
          child: Column(
            children: [
              Text(
                _diaSemanaLabels[index],
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHoje ? AppColors.brandAccent : Colors.transparent,
                ),
                child: Text(
                  '${dia.day}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isHoje ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onVerTodos;

  const _EmptySection({
    required this.title,
    required this.message,
    required this.onVerTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onVerTodos: onVerTodos),
        const SizedBox(height: 10),
        EmptyStateText(message),
      ],
    );
  }
}
