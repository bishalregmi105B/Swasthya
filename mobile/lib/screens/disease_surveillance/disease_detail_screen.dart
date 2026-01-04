import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Disease detail screen showing AI-generated comprehensive information about a specific disease
class DiseaseDetailScreen extends StatefulWidget {
  final String diseaseName;
  final Map<String, dynamic>? alertData;

  const DiseaseDetailScreen({
    super.key,
    required this.diseaseName,
    this.alertData,
  });

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? _diseaseInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiseaseInfo();
  }

  Future<void> _loadDiseaseInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final info = await apiService.getDiseaseInfo(widget.diseaseName);
      setState(() {
        _diseaseInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load disease information';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.diseaseName)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Generating AI-powered disease info...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _diseaseInfo == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.diseaseName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Unknown error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDiseaseInfo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final disease = _diseaseInfo!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(disease['name'] ?? widget.diseaseName),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getSeverityColor(disease['severity'] ?? 'moderate'),
                      _getSeverityColor(disease['severity'] ?? 'moderate')
                          .withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        disease['icon'] ?? '🦠',
                        style: const TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (disease['status'] ?? 'Active')
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadDiseaseInfo,
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Generated Badge
                  if (disease['source'] == 'AI-generated')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 16, color: Colors.purple.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'AI-Generated Content',
                            style: TextStyle(
                                color: Colors.purple.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  // Quick Stats Row
                  _buildQuickStats(disease),
                  const SizedBox(height: 24),

                  // Description
                  _buildSection(
                    'About',
                    Icons.info_outline,
                    disease['description'] ?? 'Information about this disease.',
                  ),
                  const SizedBox(height: 20),

                  // Symptoms
                  _buildListSection(
                    'Symptoms',
                    Icons.sick,
                    Colors.red,
                    (disease['symptoms'] as List<dynamic>?) ?? [],
                  ),
                  const SizedBox(height: 20),

                  // Prevention
                  _buildListSection(
                    'Prevention',
                    Icons.shield,
                    Colors.green,
                    (disease['prevention'] as List<dynamic>?) ?? [],
                  ),
                  const SizedBox(height: 20),

                  // Affected Regions
                  if (disease['affected_regions'] != null &&
                      (disease['affected_regions'] as List).isNotEmpty) ...[
                    _buildAffectedRegions(disease['affected_regions']),
                    const SizedBox(height: 20),
                  ],

                  // Risk Level Card
                  _buildRiskLevelCard(disease),
                  const SizedBox(height: 20),

                  // When to Seek Help
                  _buildEmergencySection(disease),
                  const SizedBox(height: 20),

                  // Disclaimer
                  if (disease['disclaimer'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info,
                              size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              disease['disclaimer'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> disease) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Severity',
            (disease['severity'] ?? 'Moderate').toString().toUpperCase(),
            _getSeverityColor(disease['severity'] ?? 'moderate'),
            Icons.warning_amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Transmission',
            disease['transmission'] ?? 'Variable',
            Colors.blue,
            Icons.swap_horiz,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Season',
            disease['peak_season'] ?? 'Year-round',
            Colors.orange,
            Icons.calendar_today,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(content,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
      ],
    );
  }

  Widget _buildListSection(
      String title, IconData icon, Color color, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item.toString(),
                        style: TextStyle(color: Colors.grey.shade700)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildAffectedRegions(List<dynamic> regions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, size: 20, color: Colors.purple),
            SizedBox(width: 8),
            Text('Affected Regions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: regions
              .map((region) => Chip(
                    label: Text(region.toString()),
                    backgroundColor: Colors.purple.shade50,
                    labelStyle: TextStyle(color: Colors.purple.shade700),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRiskLevelCard(Map<String, dynamic> disease) {
    final severity = disease['severity'] ?? 'moderate';
    final color = _getSeverityColor(severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: color),
              const SizedBox(width: 8),
              const Text('Risk Assessment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            disease['risk_message'] ??
                'Follow health guidelines and consult a provider if concerned.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection(Map<String, dynamic> disease) {
    final emergencySigns =
        (disease['when_to_seek_help'] as List<dynamic>?) ?? [];

    if (emergencySigns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text('When to Seek Medical Help',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          ...emergencySigns.map((sign) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: Colors.red.shade700)),
                    Expanded(
                      child: Text(
                        sign.toString(),
                        style:
                            TextStyle(color: Colors.red.shade700, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
