import 'package:flutter/material.dart';

import '../../../auth/data/models/user_model.dart';

class PerfilPage extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const PerfilPage({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Nome'),
                  subtitle: Text(user?.name ?? '—'),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('E-mail'),
                  subtitle: Text(user?.email ?? '—'),
                ),
                if (user?.role != null)
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Cargo'),
                    subtitle: Text(user!.role!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
