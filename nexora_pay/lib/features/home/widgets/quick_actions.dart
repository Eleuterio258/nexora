import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static const _actions = [
    (Icons.send_rounded, 'Enviar', AppRoutes.enviar),
    (Icons.phone_android_rounded, 'Carteira', AppRoutes.carteira),
    (Icons.receipt_long_rounded, 'Facturas', AppRoutes.facturas),
    (Icons.history_rounded, 'Historico', AppRoutes.historico),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: _actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final (icon, label, route) = _actions[index];
        return _ActionItem(
          icon: icon,
          label: label,
          route: route,
        );
      },
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D3D8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFE51116)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
