class DashboardSummary {
  const DashboardSummary({
    required this.transactionsToday,
    required this.totalVolumeToday,
    required this.activeMerchants,
    required this.totalErrors,
    required this.recentActivity,
  });

  final int transactionsToday;
  final double totalVolumeToday;
  final int activeMerchants;
  final int totalErrors;
  final List<DashboardActivity> recentActivity;
}

class DashboardActivity {
  const DashboardActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
}
