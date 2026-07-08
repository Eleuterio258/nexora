import 'package:flutter/material.dart';

import '../../data/repositories/mock_admin_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_header.dart';

class LimitsScreen extends StatelessWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MockAdminRepository().getLimitPolicies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: snapshot.error.toString(),
            onRetry: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LimitsScreen()),
            ),
          );
        }

        final policies = snapshot.data!;
        if (policies.isEmpty) {
          return const EmptyState(message: 'Nenhuma política definida');
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader('Limites por comerciante'),
            ...policies.map((policy) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(policy.merchantName),
                    subtitle: Text(
                      'Máx/segundo: ${policy.maxRequestsPerSecond}\nMáx/dia: ${policy.maxRequestsPerDay}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () {},
                      child: const Text('Editar'),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}
