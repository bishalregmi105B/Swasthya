import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/markdown_text.dart';
import '../../widgets/ai/live_ai_call_widget.dart';
import '../../providers/locale_provider.dart';

/// Disease Detail Screen - Shows detailed info about a disease
class DiseaseDetailScreen extends StatefulWidget {
  final String diseaseName;

  const DiseaseDetailScreen({super.key, required this.diseaseName});

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  String? _error;
  AICallLanguage _selectedLanguage = AICallLanguage.english;

  @override
  void initState() {
    super.initState();
    // Defer loading to use context with provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  Future<void> _loadDetails() async {
    try {
      // Get language from locale provider
      final localeProvider = context.read<LocaleProvider>();
      final language = localeProvider.languageCode;

      final data = await apiService.getDiseaseDetails(widget.diseaseName,
          language: language);
      if (mounted) {
        setState(() {
          _details = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load details';
        _isLoading = false;
      });
    }
  }

  void _showAICallBottomSheet() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAICallBottomSheet(l10n),
    );
  }

  Widget _buildAICallBottomSheet(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.talkToAIDoctor,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.diseaseName,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Context info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiWillDiscuss,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildContextItem(Icons.coronavirus,
                    '${l10n.diseases}: ${widget.diseaseName}'),
                _buildContextItem(Icons.help_outline, l10n.symptomsAndCauses),
                _buildContextItem(
                    Icons.medical_services, l10n.treatmentOptions),
                _buildContextItem(Icons.health_and_safety, l10n.preventionTips),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Language selector
          Row(
            children: [
              Text('${l10n.language}: ',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              _buildLanguageChip(l10n.english, AICallLanguage.english),
              const SizedBox(width: 8),
              _buildLanguageChip(l10n.nepali, AICallLanguage.nepali),
            ],
          ),
          const SizedBox(height: 20),

          // Call buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: Text(l10n.cancel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _startAICall();
                  },
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: Text(l10n.startAICall,
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  Widget _buildContextItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String label, AICallLanguage lang) {
    final isSelected = _selectedLanguage == lang;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _startAICall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: LiveAICallService.instance,
        child: LiveAICallWidget(
          config: LiveAICallConfig(
            specialist: 'disease-expert',
            patientContext:
                'I want to learn about ${widget.diseaseName}. Please explain this disease, its symptoms, causes, treatment options, and prevention tips.',
            systemPrompt:
                'You are a knowledgeable medical AI assistant. The user wants to learn about ${widget.diseaseName}. Provide accurate, helpful information about this disease including symptoms, causes, diagnosis, treatment, and prevention. Be empathetic and clear.',
            language: _selectedLanguage,
          ),
          title: widget.diseaseName,
          showAsBottomSheet: true,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diseaseName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: l10n.askAI,
            onPressed: _showAICallBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.coronavirus,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.diseaseName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _details?['source'] ??
                                        l10n.diseaseEncyclopedia,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _details?['disclaimer'] ?? l10n.forInfoOnly,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Content
                      if (_details?['description'] != null)
                        MarkdownText(data: _details!['description']),

                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAICallBottomSheet,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.call, color: Colors.white),
        label: Text(l10n.askAI, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
