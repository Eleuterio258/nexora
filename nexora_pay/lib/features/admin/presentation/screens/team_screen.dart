import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/team_member.dart';
import '../../data/repositories/mock_admin_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MockAdminRepository().getTeamMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: snapshot.error.toString(),
            onRetry: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TeamScreen()),
            ),
          );
        }

        final team = snapshot.data!;
        if (team.isEmpty) {
          return const EmptyState(message: 'Nenhum membro na equipa');
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader('Equipa interna'),
            ...team.map((member) => _TeamMemberCard(member)),
          ],
        );
      },
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard(this.member);

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final badgeType = member.isActive
        ? StatusBadgeType.success
        : StatusBadgeType.neutral;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Text(member.name[0]),
        ),
        title: Text(member.name),
        subtitle: Text('${member.email}\n${member.roleLabel}'),
        isThreeLine: true,
        trailing: StatusBadge(
          label: member.isActive ? 'Ativo' : 'Inativo',
          status: badgeType,
        ),
      ),
    );
  }
}
