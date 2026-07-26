import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../l10n/strings.dart';
import '../widgets/nexora_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _jobAlerts = false;
  bool _appUpdates = false;
  bool _messages = false;
  bool _profileVisible = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5EE),
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          strings.settingsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(strings.settingsNotifications),
            const SizedBox(height: 10),
            _ToggleTile(
              icon: Icons.work_outline,
              title: strings.settingsJobAlerts,
              subtitle: strings.settingsJobAlertsSub,
              value: _jobAlerts,
              onChanged: (v) => setState(() => _jobAlerts = v),
            ),
            const SizedBox(height: 8),
            _ToggleTile(
              icon: Icons.update_outlined,
              title: strings.settingsAppUpdates,
              subtitle: strings.settingsAppUpdatesSub,
              value: _appUpdates,
              onChanged: (v) => setState(() => _appUpdates = v),
            ),
            const SizedBox(height: 8),
            _ToggleTile(
              icon: Icons.chat_bubble_outline,
              title: strings.settingsMessages,
              subtitle: strings.settingsMessagesSub,
              value: _messages,
              onChanged: (v) => setState(() => _messages = v),
            ),
            const SizedBox(height: 24),
            _SectionLabel(strings.settingsPrivacy),
            const SizedBox(height: 10),
            _ToggleTile(
              icon: Icons.visibility_outlined,
              title: strings.settingsProfileVisible,
              subtitle: strings.settingsProfileVisibleSub,
              value: _profileVisible,
              onChanged: (v) => setState(() => _profileVisible = v),
            ),
            const SizedBox(height: 24),
            _SectionLabel(strings.settingsAppearance),
            const SizedBox(height: 10),
            _ToggleTile(
              icon: Icons.dark_mode_outlined,
              title: strings.settingsDarkMode,
              subtitle: strings.settingsDarkModeSub,
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
            const SizedBox(height: 24),
            _SectionLabel(strings.settingsAccount),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.lock_outline,
              title: strings.settingsChangePassword,
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.language_outlined,
              title: strings.settingsLanguage,
              trailing: strings.settingsLanguagePt,
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.help_outline,
              title: strings.settingsHelp,
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.info_outline,
              title: strings.settingsAbout,
              onTap: () {},
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _confirmLogout(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Color(0xFFE53935),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      strings.settingsLogout,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {},
              child: Center(
                child: Text(
                  strings.settingsDeleteAccount,
                  style: const TextStyle(
                    color: Color(0xFF9AA5B1),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final strings = AppStrings.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          strings.settingsLogout,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          strings.settingsLogoutConfirm,
          style: const TextStyle(color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              strings.settingsCancel,
              style: const TextStyle(color: Color(0xFF9AA5B1)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              strings.settingsLogout,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9AA5B1),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: kPrimary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A2E2A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: kPrimary,
              activeTrackColor: const Color(0xFF8ED8B4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Color(0x07000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A2E2A),
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
