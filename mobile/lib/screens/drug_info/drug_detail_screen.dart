import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/markdown_text.dart';
import '../../widgets/ai/live_ai_call_widget.dart';
import '../../providers/locale_provider.dart';

/// Drug Detail Screen - Shows detailed info about a medication
class DrugDetailScreen extends StatefulWidget {
  final String drugName;

  const DrugDetailScreen({super.key, required this.drugName});

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
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

      final data =
          await apiService.getDrugDetails(widget.drugName, language: language);

      // Cache for offline use
      await OfflineCacheService.cacheData(
          'drug_${widget.drugName}_$language', data);

      if (mounted) {
        setState(() {
          _details = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Try loading from cache
      final localeProvider = context.read<LocaleProvider>();
      final language = localeProvider.languageCode;
      final cached = OfflineCacheService.getCachedData(
          'drug_${widget.drugName}_$language');

      if (cached != null) {
        setState(() {
          _details = cached;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load details';
          _isLoading = false;
        });
      }
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.talkToAIPharmacist,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.drugName,
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
                _buildContextItem(
                    Icons.medication, '${l10n.drugInfo}: ${widget.drugName}'),
                _buildContextItem(Icons.assignment, l10n.usageAndDosage),
                _buildContextItem(Icons.warning_amber, l10n.sideEffects),
                _buildContextItem(Icons.compare_arrows, l10n.drugInteractions),
                _buildContextItem(Icons.storage, l10n.storageTips),
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
                    backgroundColor: Colors.purple,
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
          Icon(icon, size: 16, color: Colors.purple),
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
          color: isSelected ? Colors.purple : Colors.grey.shade200,
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
            specialist: 'pharmacist',
            patientContext:
                'I want to learn about ${widget.drugName} medication. Please explain its uses, dosage, side effects, interactions, and important precautions.',
            systemPrompt:
                'You are a knowledgeable pharmacist AI assistant. The user wants to learn about ${widget.drugName}. Provide accurate information about this medication including uses, dosage, side effects, drug interactions, and storage. Be clear and helpful.',
            language: _selectedLanguage,
          ),
          title: widget.drugName,
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
        title: Text(widget.drugName),
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
                              Colors.purple.shade400,
                              Colors.purple.shade600,
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
                                Icons.medication,
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
                                    widget.drugName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _details?['source'] ?? l10n.drugInformation,
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
                                _details?['disclaimer'] ??
                                    l10n.consultHealthcare,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // FDA data quick info
                      if (_details?['fda_data'] != null) ...[
                        _buildFdaSection(_details!['fda_data'], l10n),
                        const SizedBox(height: 20),
                      ],

                      // AI generated content
                      if (_details?['description'] != null)
                        MarkdownText(data: _details!['description']),

                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAICallBottomSheet,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.call, color: Colors.white),
        label: Text(l10n.askAI, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFdaSection(Map<String, dynamic> fda, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.fdaApprovedInfo,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 20),
            if (fda['indications'] != null) ...[
              Text('${l10n.indications}:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 4),
              Text(fda['indications'], style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
            ],
            if (fda['dosage'] != null) ...[
              Text('${l10n.dosage}:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 4),
              Text(fda['dosage'], style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
