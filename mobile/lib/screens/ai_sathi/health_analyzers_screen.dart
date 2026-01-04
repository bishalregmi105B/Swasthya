import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';

/// Health Analyzers Selection Screen
/// Lists all available AI health analysis tools
class HealthAnalyzersScreen extends StatelessWidget {
  const HealthAnalyzersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthAnalyzers),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.document_scanner,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Health Analysis',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload health documents for instant AI analysis',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section Title
              Text(
                'Select Analysis Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Analyzer Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: _buildAnalyzerCards(context, isDark),
              ),

              const SizedBox(height: 24),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI analysis is for informational purposes only. Always consult a healthcare professional.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade800),
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

  List<Widget> _buildAnalyzerCards(BuildContext context, bool isDark) {
    final analyzers = [
      _AnalyzerType(
        id: 'lab_report',
        title: 'Lab Report',
        subtitle: 'CBC, Blood Tests',
        icon: Icons.biotech,
        color: Colors.blue,
      ),
      _AnalyzerType(
        id: 'prescription',
        title: 'Prescription',
        subtitle: 'Medicine Rx',
        icon: Icons.medication,
        color: Colors.purple,
      ),
      _AnalyzerType(
        id: 'skin',
        title: 'Skin Condition',
        subtitle: 'Dermatology',
        icon: Icons.face_retouching_natural,
        color: Colors.orange,
      ),
      _AnalyzerType(
        id: 'xray',
        title: 'X-Ray / Scan',
        subtitle: 'X-ray, CT, MRI',
        icon: Icons.medical_services,
        color: Colors.teal,
      ),
      _AnalyzerType(
        id: 'ecg',
        title: 'ECG Report',
        subtitle: 'Heart Monitoring',
        icon: Icons.monitor_heart,
        color: Colors.red,
      ),
      _AnalyzerType(
        id: 'general',
        title: 'General Health',
        subtitle: 'Any Document',
        icon: Icons.health_and_safety,
        color: Colors.green,
      ),
    ];

    return analyzers.map((analyzer) {
      return _buildAnalyzerCard(context, analyzer, isDark);
    }).toList();
  }

  Widget _buildAnalyzerCard(
      BuildContext context, _AnalyzerType analyzer, bool isDark) {
    return InkWell(
      onTap: () => context.push('/ai-scan/${analyzer.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: analyzer.color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: analyzer.color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: analyzer.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(analyzer.icon, color: analyzer.color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              analyzer.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              analyzer.subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzerType {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _AnalyzerType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
