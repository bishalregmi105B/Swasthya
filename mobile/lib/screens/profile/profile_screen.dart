import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 32,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user?.fullName ?? 'User',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(user?.email ?? '',
                    style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildMenuItem(context, Icons.person_outline,
              l10n.personalInformation, () => context.push('/edit-profile')),
          _buildMenuItem(context, Icons.medical_information_outlined,
              l10n.medicalHistory, () => context.push('/medical-history')),
          _buildMenuItem(context, Icons.calendar_today_outlined,
              l10n.myAppointments, () => context.push('/appointments')),
          _buildMenuItem(context, Icons.medication_outlined, l10n.myMedicines,
              () => context.push('/reminders')),
          const Divider(height: 32),
          _buildMenuItem(context, Icons.settings_outlined, l10n.settings,
              () => context.push('/settings')),
          _buildMenuItem(context, Icons.help_outline, 'Help & Support', () {}),
          _buildMenuItem(
              context, Icons.privacy_tip_outlined, l10n.privacy, () {}),
          const Divider(height: 32),
          _buildMenuItem(context, Icons.logout, l10n.logout, () async {
            await context.read<AuthProvider>().logout();
            if (context.mounted) context.go('/login');
          }, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
