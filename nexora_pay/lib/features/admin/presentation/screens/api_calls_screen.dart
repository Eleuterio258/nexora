import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/api_call.dart';
import '../../data/repositories/mock_admin_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_header.dart';

class ApiCallsScreen extends StatelessWidget {
  const ApiCallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MockAdminRepository().getApiCalls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: snapshot.error.toString(),
            onRetry: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ApiCallsScreen()),
            ),
          );
        }

        final calls = snapshot.data!;
        if (calls.isEmpty) {
          return const EmptyState(message: 'Nenhuma chamada registada');
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader('Registo de chamadas'),
            ...calls.map((call) => _ApiCallCard(call)),
          ],
        );
      },
    );
  }
}

class _ApiCallCard extends StatelessWidget {
  const _ApiCallCard(this.call);

  final ApiCall call;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: call.isError ? AppColors.primaryLight : const Color(0xFFE6F4F1),
          foregroundColor: call.isError ? AppColors.error : AppColors.success,
          child: Icon(call.isError ? Icons.error_outline : Icons.check),
        ),
        title: Text('${call.method} ${call.endpoint}'),
        subtitle: Text(
          '${call.merchantName}\n${call.errorMessage ?? 'Status ${call.statusCode}'}',
        ),
        isThreeLine: true,
        trailing: Text(
          DateFormat('HH:mm').format(call.timestamp),
          style: const TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
