import 'package:flutter/material.dart';
import '../widgets/nexora_logo.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String role;
  final String company;
  final Color avatarColor;
  final bool online;

  const ChatScreen({
    super.key,
    required this.name,
    required this.role,
    required this.company,
    required this.avatarColor,
    this.online = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final List<_Msg> _messages = [
    _Msg(
      text: 'Hi! Thanks for applying to the Senior Product Designer role. Your portfolio is impressive!',
      isMe: false,
      time: '10:28 AM',
    ),
    _Msg(
      text: 'Would you be available for a 30-minute call this week to discuss the position?',
      isMe: false,
      time: '10:29 AM',
    ),
    _Msg(
      text: 'Thank you so much! I\'m very interested in the role.',
      isMe: true,
      time: '10:45 AM',
    ),
    _Msg(
      text: 'I\'m available Wednesday or Thursday afternoon. Would either of those work?',
      isMe: true,
      time: '10:45 AM',
    ),
    _Msg(
      text: 'Thursday at 3 PM works perfectly! I\'ll send you a calendar invite.',
      isMe: false,
      time: '11:02 AM',
    ),
    _Msg(
      text: 'Please bring any questions you have about the team and the product vision.',
      isMe: false,
      time: '11:03 AM',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isMe: true, time: _nowTime()));
      _ctrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _nowTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E2A)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.avatarColor,
                  child: Text(
                    widget.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (widget.online)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Color(0xFF1A2E2A),
                    ),
                  ),
                  Text(
                    widget.online ? 'Online' : '${widget.role} • ${widget.company}',
                    style: TextStyle(
                      color: widget.online ? kPrimary : Colors.grey.shade500,
                      fontSize: 11.5,
                      fontWeight: widget.online ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Color(0xFF1A2E2A), size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Color(0xFF1A2E2A), size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _BubbleWidget(msg: _messages[i]),
            ),
          ),

          // Input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F6),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: 'Type a message…',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.attach_file_outlined,
                                color: Colors.grey.shade400, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isMe;
  final String time;
  const _Msg({required this.text, required this.isMe, required this.time});
}

class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  const _BubbleWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? kPrimary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : const Color(0xFF1A2E2A),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: TextStyle(
                color: msg.isMe
                    ? const Color.fromRGBO(255, 255, 255, 0.65)
                    : Colors.grey.shade400,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
