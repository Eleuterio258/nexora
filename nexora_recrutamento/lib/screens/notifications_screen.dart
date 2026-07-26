import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/notifications/data/models/notification_model.dart';
import '../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../l10n/strings.dart';
import '../widgets/nexora_logo.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const NotificationsLoadRequested());
  }

  void _markAllRead() {
    context.read<NotificationsBloc>().add(const AllNotificationsMarkedAsRead());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                const Positioned.fill(child: GreenHeaderDecoration()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          const NexoraLogoIcon(size: 24, isWhite: true),
                          const SizedBox(width: 8),
                          const Text(
                            'Nexora',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          BlocBuilder<NotificationsBloc, NotificationsState>(
                            builder: (context, state) {
                              final unread = state is NotificationsLoaded
                                  ? state.notifications.where((n) => !n.lida).length
                                  : 0;
                              if (unread == 0) return const SizedBox.shrink();
                              return TextButton(
                                onPressed: _markAllRead,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  strings.notifMarkAllRead,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            strings.notifTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          BlocBuilder<NotificationsBloc, NotificationsState>(
                            builder: (context, state) {
                              final unread = state is NotificationsLoaded
                                  ? state.notifications.where((n) => !n.lida).length
                                  : 0;
                              if (unread == 0) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5252),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$unread ${strings.notifNew}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.notifSubtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: BlocBuilder<NotificationsBloc, NotificationsState>(
                  builder: (context, state) {
                    if (state is NotificationsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final notifications = state is NotificationsLoaded
                        ? state.notifications
                        : <NotificationModel>[];

                    if (notifications.isEmpty) {
                      return Center(
                        child: Text(
                          strings.notifEmpty,
                          style: const TextStyle(
                            color: Color(0xFF9AA5B1),
                            fontSize: 15,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _NotifCard(
                        notif: notifications[i],
                        onTap: () => context
                            .read<NotificationsBloc>()
                            .add(NotificationMarkedAsRead(notifications[i].id)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotifCard({required this.notif, required this.onTap});

  IconData get _typeIcon {
    switch (notif.tipo) {
      case 'interview':
        return Icons.event_available_outlined;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'job':
        return Icons.work_outline_rounded;
      case 'application':
        return Icons.send_rounded;
      case 'status':
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color get _typeColor {
    switch (notif.tipo) {
      case 'interview':
        return const Color(0xFFE57C00);
      case 'message':
        return const Color(0xFF4A90D9);
      case 'job':
        return const Color(0xFF8A7AB5);
      case 'application':
        return kPrimary;
      case 'status':
      default:
        return kPrimary;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: notif.lida ? Colors.white : const Color(0xFFF0FBF5),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x07000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: notif.lida
              ? null
              : Border.all(color: const Color(0xFFB8EDD4), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _typeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _typeIcon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.titulo,
                            style: TextStyle(
                              fontWeight: notif.lida
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              fontSize: 13.5,
                              color: const Color(0xFF1A2E2A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notif.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                        if (!notif.lida) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: kPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.corpo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
