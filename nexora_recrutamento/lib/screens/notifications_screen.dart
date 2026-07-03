import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotifData> _notifs = [
    _NotifData(
      type: _NotifType.application,
      title: 'Application Received',
      body: 'Google has received your application for Product Designer.',
      time: '10 min ago',
      read: false,
      avatarBg: const Color(0xFF1A1A2E),
      avatarText: 'G',
    ),
    _NotifData(
      type: _NotifType.interview,
      title: 'Interview Scheduled',
      body: 'Upwork confirmed your interview for Senior Product Designer on Thursday at 3 PM.',
      time: '1 h ago',
      read: false,
      avatarBg: const Color(0xFF1DBF73),
      avatarText: 'up',
    ),
    _NotifData(
      type: _NotifType.message,
      title: 'New Message',
      body: 'Aishwarya Sharma: "Hi! Thanks for applying. Let\'s schedule a quick call…"',
      time: '2 h ago',
      read: false,
      avatarBg: const Color(0xFFB5937A),
      avatarText: 'A',
    ),
    _NotifData(
      type: _NotifType.status,
      title: 'Status Update',
      body: 'Your application at Amazon is now In Review.',
      time: 'Yesterday',
      read: true,
      avatarBg: const Color(0xFF1A1A1A),
      avatarText: 'amazon',
    ),
    _NotifData(
      type: _NotifType.job,
      title: 'New Job Match',
      body: 'A new job matching your profile: "Lead Product Designer" at Spotify.',
      time: 'Yesterday',
      read: true,
      avatarBg: const Color(0xFF1DB954),
      avatarText: 'S',
    ),
    _NotifData(
      type: _NotifType.message,
      title: 'New Message',
      body: 'Rahul Mehta: "Your profile looks great! Are you available for…"',
      time: '2 days ago',
      read: true,
      avatarBg: const Color(0xFF7A9BB5),
      avatarText: 'R',
    ),
    _NotifData(
      type: _NotifType.job,
      title: 'New Job Match',
      body: '"Senior UX Designer" at Airbnb is a great match for your skills.',
      time: '3 days ago',
      read: true,
      avatarBg: const Color(0xFFFF5A5F),
      avatarText: 'A',
    ),
    _NotifData(
      type: _NotifType.status,
      title: 'Application Shortlisted',
      body: 'Congratulations! You\'ve been shortlisted at Microsoft for UI/UX Designer.',
      time: '4 days ago',
      read: true,
      avatarBg: const Color(0xFF1A1A2E),
      avatarText: 'MS',
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifs) {
        n.read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Green header
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
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 22),
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
                          if (unread > 0)
                            TextButton(
                              onPressed: _markAllRead,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$unread new',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Stay up to date with your job search',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Body
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5EE),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _notifs.isEmpty
                    ? const Center(
                        child: Text(
                          'No notifications yet',
                          style:
                              TextStyle(color: Color(0xFF9AA5B1), fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        itemCount: _notifs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) => _NotifCard(
                          notif: _notifs[i],
                          onTap: () =>
                              setState(() => _notifs[i].read = true),
                          onDismiss: () =>
                              setState(() => _notifs.removeAt(i)),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NotifType { application, interview, message, status, job }

class _NotifData {
  final _NotifType type;
  final String title;
  final String body;
  final String time;
  bool read;
  final Color avatarBg;
  final String avatarText;

  _NotifData({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
    required this.avatarBg,
    required this.avatarText,
  });
}

class _NotifCard extends StatelessWidget {
  final _NotifData notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifCard({
    required this.notif,
    required this.onTap,
    required this.onDismiss,
  });

  IconData get _typeIcon {
    switch (notif.type) {
      case _NotifType.interview:
        return Icons.event_available_outlined;
      case _NotifType.message:
        return Icons.chat_bubble_outline_rounded;
      case _NotifType.status:
        return Icons.info_outline_rounded;
      case _NotifType.job:
        return Icons.work_outline_rounded;
      case _NotifType.application:
        return Icons.send_rounded;
    }
  }

  Color get _typeColor {
    switch (notif.type) {
      case _NotifType.interview:
        return const Color(0xFFE57C00);
      case _NotifType.message:
        return const Color(0xFF4A90D9);
      case _NotifType.status:
        return kPrimary;
      case _NotifType.job:
        return const Color(0xFF8A7AB5);
      case _NotifType.application:
        return kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.title + notif.time),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline,
            color: Color(0xFFE53935), size: 22),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: notif.read ? Colors.white : const Color(0xFFF0FBF5),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x07000000),
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
            border: notif.read
                ? null
                : Border.all(
                    color: const Color(0xFFB8EDD4), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with type badge
                Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: notif.avatarBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          notif.avatarText,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: notif.avatarText.length > 2 ? 9 : 15,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _typeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(_typeIcon,
                            color: Colors.white, size: 10),
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
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.read
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                fontSize: 13.5,
                                color: const Color(0xFF1A2E2A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notif.time,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                          if (!notif.read) ...[
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
                        notif.body,
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
      ),
    );
  }
}
