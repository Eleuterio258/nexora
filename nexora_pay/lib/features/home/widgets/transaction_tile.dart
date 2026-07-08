import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.positive = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFCE5E6),
        foregroundColor: const Color(0xFFE51116),
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: positive ? const Color(0xFF15803D) : const Color(0xFFB42318),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
