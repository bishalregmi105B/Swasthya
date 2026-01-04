import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/health_mode_provider.dart';
import '../../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final healthModeProvider = context.watch<HealthModeProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // Health Mode Setting
          ListTile(
            leading: Icon(
              healthModeProvider.isAyurvedic ? Icons.eco : Icons.science,
              color: healthModeProvider.isAyurvedic
                  ? Colors.green
                  : AppColors.primary,
            ),
            title: Text(l10n.healthApproach),
            subtitle: Text(
              healthModeProvider.isAyurvedic
                  ? 'Ayurvedic - Traditional & Holistic 🌿'
                  : 'Scientific - Evidence-Based 🔬',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHealthModeDialog(context, healthModeProvider),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle:
                Text(localeProvider.isEnglish ? l10n.english : l10n.nepali),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, l10n, localeProvider),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: Text(l10n.darkMode),
            value: themeProvider.isDarkMode,
            onChanged: (v) => themeProvider.toggleTheme(),
            activeColor: AppColors.primary,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.notifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            trailing: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  void _showHealthModeDialog(
      BuildContext context, HealthModeProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Health Approach',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how AI should respond to your health queries',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Scientific Mode
            _buildModeOption(
              context,
              provider,
              isAyurvedic: false,
              icon: Icons.science,
              color: Colors.blue,
              title: 'Scientific / Allopathic 🔬',
              description:
                  'Evidence-based medicine, clinical approach, modern treatments and medications',
            ),
            const SizedBox(height: 12),

            // Ayurvedic Mode
            _buildModeOption(
              context,
              provider,
              isAyurvedic: true,
              icon: Icons.eco,
              color: Colors.green,
              title: 'Ayurvedic / Traditional 🌿',
              description:
                  'Holistic healing, dosha balance, natural remedies, yoga & lifestyle',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context,
    HealthModeProvider provider, {
    required bool isAyurvedic,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final isSelected = provider.isAyurvedic == isAyurvedic;

    return InkWell(
      onTap: () {
        if (isAyurvedic) {
          provider.setAyurvedic();
        } else {
          provider.setScientific();
        }
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations l10n,
      LocaleProvider localeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.english),
              leading: Radio<bool>(
                value: true,
                groupValue: localeProvider.isEnglish,
                onChanged: (v) {
                  localeProvider.setEnglish();
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                localeProvider.setEnglish();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.nepali),
              leading: Radio<bool>(
                value: false,
                groupValue: localeProvider.isEnglish,
                onChanged: (v) {
                  localeProvider.setNepali();
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                localeProvider.setNepali();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
