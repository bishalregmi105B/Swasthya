import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';

/// Ayurvedic Doctors Selection Screen
/// Lists all available traditional medicine practitioners
class AyurvedicDoctorsScreen extends StatelessWidget {
  const AyurvedicDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final specialists = [
      _AyurvedicSpecialist(
        id: 'vaidya',
        title: 'Ayurvedic Vaidya',
        subtitle: 'General Wellness',
        description: 'Dosha balance, herbal remedies, Prakriti analysis',
        icon: Icons.eco,
        color: Colors.green,
      ),
      _AyurvedicSpecialist(
        id: 'panchakarma',
        title: 'Panchakarma Expert',
        subtitle: 'Detox & Rejuvenation',
        description: 'Cleansing therapies, body purification, toxin removal',
        icon: Icons.spa,
        color: Colors.teal,
      ),
      _AyurvedicSpecialist(
        id: 'yoga_therapist',
        title: 'Yoga Therapist',
        subtitle: 'Mind & Body',
        description: 'Asanas, pranayama, meditation, stress relief',
        icon: Icons.self_improvement,
        color: Colors.purple,
      ),
      _AyurvedicSpecialist(
        id: 'naturopath',
        title: 'Naturopathy Expert',
        subtitle: 'Natural Healing',
        description: 'Hydrotherapy, mud therapy, fasting, diet therapy',
        icon: Icons.local_florist,
        color: Colors.orange,
      ),
      _AyurvedicSpecialist(
        id: 'unani',
        title: 'Unani Medicine',
        subtitle: 'Greco-Arabic Medicine',
        description: 'Herbal compounds, regimental therapy, humoral balance',
        icon: Icons.local_pharmacy,
        color: Colors.brown,
      ),
      _AyurvedicSpecialist(
        id: 'homeopath',
        title: 'Homeopathy Expert',
        subtitle: 'Like Cures Like',
        description:
            'Diluted remedies, constitutional treatment, holistic care',
        icon: Icons.water_drop,
        color: Colors.blue,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ayurvedicDoctors),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.15),
                    Colors.teal.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🌿', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Traditional Medicine',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consult with AI specialists in ancient healing practices',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Disclaimer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.aiDisclaimer,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.amber.shade200
                            : Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Specialists List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: specialists.length,
                itemBuilder: (context, index) {
                  final specialist = specialists[index];
                  return _buildSpecialistCard(context, specialist, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistCard(
    BuildContext context,
    _AyurvedicSpecialist specialist,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.push('/ai-chat/${specialist.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: specialist.color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: specialist.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: specialist.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(specialist.icon, color: specialist.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        specialist.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: specialist.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          specialist.subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: specialist.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    specialist.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _AyurvedicSpecialist {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  _AyurvedicSpecialist({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
