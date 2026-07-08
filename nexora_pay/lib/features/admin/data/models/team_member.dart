enum TeamRole { admin, support, viewer }

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final TeamRole role;
  final bool isActive;
  final DateTime joinedAt;

  String get roleLabel => switch (role) {
        TeamRole.admin => 'Administrador',
        TeamRole.support => 'Suporte',
        TeamRole.viewer => 'Visualizador',
      };
}
