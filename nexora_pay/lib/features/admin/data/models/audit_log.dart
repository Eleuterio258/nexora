class AuditLog {
  const AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.target,
    required this.details,
    required this.timestamp,
  });

  final String id;
  final String userId;
  final String userName;
  final String action;
  final String target;
  final String details;
  final DateTime timestamp;
}
