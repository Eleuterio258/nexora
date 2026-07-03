import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const _conversations = [
    _ConvData(
      name: 'Aishwarya Sharma',
      role: 'Talent Acquisition Specialist',
      company: 'TechNova',
      preview: 'Hi! Thanks for applying: Let\'s schedule a quick...',
      time: '10:30 AM',
      unread: 2,
      online: true,
      avatarColor: Color(0xFFB5937A),
    ),
    _ConvData(
      name: 'Rahul Mehta',
      role: 'Senior Recruiter',
      company: 'CloudScale',
      preview: 'Your profile looks great! Are you available for...',
      time: 'Yesterday',
      unread: 1,
      online: false,
      avatarColor: Color(0xFF7A9BB5),
    ),
    _ConvData(
      name: 'Neha Kapoor',
      role: 'HR Manager',
      company: 'Innotech Solutions',
      preview: "We'd love to move forward with the next round...",
      time: 'Yesterday',
      unread: 0,
      online: false,
      avatarColor: Color(0xFF8A7AB5),
    ),
    _ConvData(
      name: 'Vikram Singh',
      role: 'Technical Recruiter',
      company: 'DevBridge',
      preview: 'Can you share your availability for a technical...',
      time: 'Mon',
      unread: 0,
      online: false,
      avatarColor: Color(0xFF7AB58A),
    ),
    _ConvData(
      name: 'Priya Nair',
      role: 'People Partner',
      company: 'BrightWare',
      preview: 'Thanks for your interest in our company! We...',
      time: 'Sun',
      unread: 0,
      online: false,
      avatarColor: Color(0xFFB58A7A),
    ),
    _ConvData(
      name: 'Arjun Desai',
      role: 'Lead Recruiter',
      company: 'NexGen AI',
      preview: "Shortlisted! Let's connect for an interview.",
      time: 'Sat',
      unread: 0,
      online: false,
      avatarColor: Color(0xFF6A7AB5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nexora',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Color(0xFF1A2E2A), size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Messages',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2E2A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search messages',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    Icon(Icons.tune, color: Colors.grey.shade500, size: 20),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Conversation list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.grey.shade100,
                  height: 1,
                  indent: 84,
                ),
                itemBuilder: (context, i) =>
                    _ConversationTile(conv: _conversations[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConvData {
  final String name;
  final String role;
  final String company;
  final String preview;
  final String time;
  final int unread;
  final bool online;
  final Color avatarColor;

  const _ConvData({
    required this.name,
    required this.role,
    required this.company,
    required this.preview,
    required this.time,
    required this.unread,
    required this.online,
    required this.avatarColor,
  });
}

class _ConversationTile extends StatelessWidget {
  final _ConvData conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            name: conv.name,
            role: conv.role,
            company: conv.company,
            avatarColor: conv.avatarColor,
            online: conv.online,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: conv.avatarColor,
                  child: Text(
                    conv.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (conv.online)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conv.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A2E2A),
                        ),
                      ),
                      Text(
                        conv.time,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${conv.role} • ${conv.company}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                      if (conv.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${conv.unread}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
