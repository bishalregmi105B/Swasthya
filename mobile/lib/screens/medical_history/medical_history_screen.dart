import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';
import '../../widgets/ai/markdown_text.dart';
import '../../services/offline_cache_service.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _medicalRecord;
  List<dynamic> _conditions = [];
  List<dynamic> _allergies = [];
  List<dynamic> _medications = [];
  List<dynamic> _documents = [];
  List<dynamic> _surgeries = [];
  List<dynamic> _vaccinations = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        apiService.getMedicalRecord(includeDetails: true),
        apiService.getMedicalConditions(),
        apiService.getMedicalAllergies(),
        apiService.getMedicalMedications(),
        apiService.getMedicalDocuments(),
        apiService.getMedicalSurgeries(),
        apiService.getMedicalVaccinations(),
      ]);

      // Cache all data for offline use
      await _cacheAllData(results);

      setState(() {
        _medicalRecord = results[0] as Map<String, dynamic>;
        _conditions = results[1] as List<dynamic>;
        _allergies = results[2] as List<dynamic>;
        _medications = results[3] as List<dynamic>;
        _documents = results[4] as List<dynamic>;
        _surgeries = results[5] as List<dynamic>;
        _vaccinations = results[6] as List<dynamic>;
        _isLoading = false;
        _isOffline = false;
      });
    } catch (e) {
      // Try to load from offline cache
      await _loadFromCache();
    }
  }

  Future<void> _cacheAllData(List<dynamic> results) async {
    try {
      await OfflineCacheService.cacheMedicalRecord(
          results[0] as Map<String, dynamic>);
      await OfflineCacheService.cacheMedicalConditions(
          List<Map<String, dynamic>>.from(
              (results[1] as List).map((e) => Map<String, dynamic>.from(e))));
      await OfflineCacheService.cacheMedicalAllergies(
          List<Map<String, dynamic>>.from(
              (results[2] as List).map((e) => Map<String, dynamic>.from(e))));
      await OfflineCacheService.cacheMedicalMedications(
          List<Map<String, dynamic>>.from(
              (results[3] as List).map((e) => Map<String, dynamic>.from(e))));
      await OfflineCacheService.cacheMedicalDocuments(
          List<Map<String, dynamic>>.from(
              (results[4] as List).map((e) => Map<String, dynamic>.from(e))));
      await OfflineCacheService.cacheMedicalSurgeries(
          List<Map<String, dynamic>>.from(
              (results[5] as List).map((e) => Map<String, dynamic>.from(e))));
      await OfflineCacheService.cacheMedicalVaccinations(
          List<Map<String, dynamic>>.from(
              (results[6] as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (e) {
      debugPrint('[MedicalHistory] Cache error: $e');
    }
  }

  Future<void> _loadFromCache() async {
    final cachedRecord = OfflineCacheService.getCachedMedicalRecord();
    final cachedConditions = OfflineCacheService.getCachedMedicalConditions();
    final cachedAllergies = OfflineCacheService.getCachedMedicalAllergies();
    final cachedMedications = OfflineCacheService.getCachedMedicalMedications();
    final cachedDocuments = OfflineCacheService.getCachedMedicalDocuments();
    final cachedSurgeries = OfflineCacheService.getCachedMedicalSurgeries();
    final cachedVaccinations =
        OfflineCacheService.getCachedMedicalVaccinations();

    if (cachedRecord != null) {
      setState(() {
        _medicalRecord = cachedRecord;
        _conditions = cachedConditions ?? [];
        _allergies = cachedAllergies ?? [];
        _medications = cachedMedications ?? [];
        _documents = cachedDocuments ?? [];
        _surgeries = cachedSurgeries ?? [];
        _vaccinations = cachedVaccinations ?? [];
        _isLoading = false;
        _isOffline = true;
      });
    } else {
      setState(() {
        _isLoading = false;
        _isOffline = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline - No cached data available')),
        );
      }
    }
  }

  void _openAIConsultation() async {
    try {
      final contextData = await apiService.getMedicalHistoryAIContext();
      if (!mounted) return;

      showLiveAICallBottomSheet(
        context: context,
        config: LiveAICallConfig(
          specialist: 'physician',
          patientContext:
              'User is reviewing their medical history. Help them understand their health records and provide guidance.\n\n${contextData['context'] ?? ''}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicalHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Consultation',
            onPressed: _openAIConsultation,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Conditions'),
            Tab(text: 'Allergies'),
            Tab(text: 'Medications'),
            Tab(text: 'Documents'),
            Tab(text: 'More'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildConditionsTab(),
                _buildAllergiesTab(),
                _buildMedicationsTab(),
                _buildDocumentsTab(),
                _buildMoreTab(),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAIConsultation,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Ask AI'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info Card
            _buildInfoCard(
              title: 'Basic Information',
              icon: Icons.person_outline,
              children: [
                _buildInfoRow(
                    'Blood Type', _medicalRecord?['blood_type'] ?? 'Not set'),
                _buildInfoRow(
                    'Height',
                    _medicalRecord?['height_cm'] != null
                        ? '${_medicalRecord!['height_cm']} cm'
                        : 'Not set'),
                _buildInfoRow(
                    'Weight',
                    _medicalRecord?['weight_kg'] != null
                        ? '${_medicalRecord!['weight_kg']} kg'
                        : 'Not set'),
                _buildInfoRow('Organ Donor',
                    _medicalRecord?['organ_donor'] == true ? 'Yes' : 'No'),
              ],
              onEdit: () => _showEditBasicInfo(),
            ),
            const SizedBox(height: 16),

            // Quick Stats
            Row(
              children: [
                Expanded(
                    child: _buildStatCard('Conditions', _conditions.length,
                        Icons.medical_information, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard('Allergies', _allergies.length,
                        Icons.warning_amber, Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard('Medications', _medications.length,
                        Icons.medication, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard('Documents', _documents.length,
                        Icons.folder, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard('Surgeries', _surgeries.length,
                        Icons.local_hospital, Colors.purple)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatCard('Vaccinations', _vaccinations.length,
                        Icons.vaccines, Colors.teal)),
              ],
            ),
            const SizedBox(height: 16),

            // Emergency Notes
            if (_medicalRecord?['emergency_notes'] != null)
              _buildInfoCard(
                title: 'Emergency Notes',
                icon: Icons.emergency,
                color: Colors.red,
                children: [
                  Text(_medicalRecord!['emergency_notes']),
                ],
              ),

            // Recent Conditions
            if (_conditions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Active Conditions',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._conditions.take(2).map((c) => _buildConditionCard(c)),
            ],

            // Recent Allergies
            if (_allergies.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Allergies', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._allergies.take(2).map((a) => _buildAllergyCard(a)),
            ],

            // Recent Medications
            if (_medications.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Active Medications',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._medications.take(2).map((m) => _buildMedicationCard(m)),
            ],

            // Recent Surgeries
            if (_surgeries.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Surgical History',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._surgeries.take(2).map((s) => _buildSurgeryCard(s)),
            ],

            // Recent Vaccinations
            if (_vaccinations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Recent Vaccinations',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._vaccinations.take(2).map((v) => _buildVaccinationCard(v)),
            ],

            // Recent Documents
            if (_documents.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Recent Documents',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._documents.take(3).map((doc) => _buildDocumentCard(doc)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsTab() {
    return _buildListTab(
      items: _conditions,
      emptyMessage: 'No medical conditions recorded',
      emptyIcon: Icons.health_and_safety,
      itemBuilder: (condition) => _buildConditionCard(condition),
      onAdd: () => _showAddConditionDialog(),
    );
  }

  Widget _buildAllergiesTab() {
    return _buildListTab(
      items: _allergies,
      emptyMessage: 'No allergies recorded',
      emptyIcon: Icons.warning_amber,
      itemBuilder: (allergy) => _buildAllergyCard(allergy),
      onAdd: () => _showAddAllergyDialog(),
    );
  }

  Widget _buildMedicationsTab() {
    return _buildListTab(
      items: _medications,
      emptyMessage: 'No medications recorded',
      emptyIcon: Icons.medication,
      itemBuilder: (medication) => _buildMedicationCard(medication),
      onAdd: () => _showAddMedicationDialog(),
    );
  }

  Widget _buildDocumentsTab() {
    return _buildListTab(
      items: _documents,
      emptyMessage: 'No documents uploaded',
      emptyIcon: Icons.folder_open,
      itemBuilder: (doc) => _buildDocumentCard(doc),
      onAdd: () => context.push('/medical-history/add-document'),
    );
  }

  Widget _buildMoreTab() {
    return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Surgeries (${_surgeries.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _showAddSurgeryDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_surgeries.isEmpty)
                const Text('No surgical history recorded')
              else
                ..._surgeries.map((s) => _buildSurgeryCard(s)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vaccinations (${_vaccinations.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _showAddVaccinationDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_vaccinations.isEmpty)
                const Text('No vaccinations recorded')
              else
                ..._vaccinations.map((v) => _buildVaccinationCard(v)),
            ],
          ),
        ));
  }

  Widget _buildListTab({
    required List<dynamic> items,
    required String emptyMessage,
    required IconData emptyIcon,
    required Widget Function(dynamic) itemBuilder,
    required VoidCallback onAdd,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder(items[index]),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'add_${items.hashCode}',
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
    VoidCallback? onEdit,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color ?? AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text('$count',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(Map<String, dynamic> condition) {
    final severity = condition['severity'] ?? 'unknown';
    final status = condition['status'] ?? 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          Icons.medical_information,
          color: severity == 'severe'
              ? Colors.red
              : severity == 'moderate'
                  ? Colors.orange
                  : Colors.green,
        ),
        title: Text(condition['name'] ?? ''),
        subtitle: Text('$severity • $status'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (condition['diagnosed_date'] != null)
                  Text('Diagnosed: ${condition['diagnosed_date']}'),
                if (condition['treatment'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Treatment: ${condition['treatment']}'),
                ],
                if (condition['ai_analysis'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('AI Analysis',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(condition['ai_analysis'],
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyCard(Map<String, dynamic> allergy) {
    final severity = allergy['severity'] ?? 'unknown';
    final severityColor = severity == 'life_threatening'
        ? Colors.red
        : severity == 'severe'
            ? Colors.orange
            : Colors.amber;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severityColor.withOpacity(0.2),
          child: Icon(Icons.warning, color: severityColor),
        ),
        title: Text(allergy['allergen'] ?? ''),
        subtitle: Text(
            '${allergy['category'] ?? ''} • ${severity.replaceAll('_', ' ')}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteAllergy(allergy['id']),
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.medication, color: Colors.white),
        ),
        title: Text(medication['name'] ?? ''),
        subtitle: Text(
            '${medication['dosage'] ?? ''} • ${medication['frequency'] ?? ''}'),
        trailing: medication['is_active'] == true
            ? const Chip(
                label: Text('Active', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.green)
            : const Chip(
                label: Text('Inactive', style: TextStyle(fontSize: 12))),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDocumentDetails(doc),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      _getDocTypeColor(doc['document_type']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getDocTypeIcon(doc['document_type']),
                    color: _getDocTypeColor(doc['document_type'])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${doc['document_type']?.replaceAll('_', ' ') ?? ''} • ${doc['document_date'] ?? ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (doc['ai_summary'] != null)
                      Text(doc['ai_summary'],
                          style:
                              const TextStyle(fontSize: 11, color: Colors.blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (doc['is_critical'] == true)
                const Icon(Icons.priority_high, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurgeryCard(Map<String, dynamic> surgery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.local_hospital, color: Colors.white),
        ),
        title: Text(surgery['procedure_name'] ?? ''),
        subtitle: Text(
            '${surgery['surgery_date'] ?? ''} • ${surgery['hospital_name'] ?? ''}'),
      ),
    );
  }

  Widget _buildVaccinationCard(Map<String, dynamic> vaccination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.vaccines, color: Colors.white),
        ),
        title: Text(vaccination['vaccine_name'] ?? ''),
        subtitle: Text(
            'Dose ${vaccination['dose_number'] ?? '?'}/${vaccination['total_doses'] ?? '?'} • ${vaccination['administered_date'] ?? ''}'),
      ),
    );
  }

  IconData _getDocTypeIcon(String? type) {
    switch (type) {
      case 'lab_report':
        return Icons.science;
      case 'prescription':
        return Icons.receipt_long;
      case 'xray':
        return Icons.image;
      case 'mri':
      case 'ct_scan':
        return Icons.scanner;
      case 'blood_test':
        return Icons.bloodtype;
      case 'vaccination':
        return Icons.vaccines;
      default:
        return Icons.description;
    }
  }

  Color _getDocTypeColor(String? type) {
    switch (type) {
      case 'lab_report':
        return Colors.purple;
      case 'prescription':
        return Colors.blue;
      case 'xray':
      case 'mri':
      case 'ct_scan':
        return Colors.indigo;
      case 'blood_test':
        return Colors.red;
      case 'vaccination':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Dialog methods
  void _showEditBasicInfo() {
    final bloodTypeController =
        TextEditingController(text: _medicalRecord?['blood_type']);
    final heightController = TextEditingController(
        text: _medicalRecord?['height_cm']?.toString() ?? '');
    final weightController = TextEditingController(
        text: _medicalRecord?['weight_kg']?.toString() ?? '');
    final emergencyNotesController =
        TextEditingController(text: _medicalRecord?['emergency_notes'] ?? '');
    bool organDonor = _medicalRecord?['organ_donor'] ?? false;
    String? smokingStatus = _medicalRecord?['smoking_status'];
    String? alcoholUse = _medicalRecord?['alcohol_use'];
    String? exerciseFrequency = _medicalRecord?['exercise_frequency'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Basic Information',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: bloodTypeController.text.isEmpty
                      ? null
                      : bloodTypeController.text,
                  decoration: const InputDecoration(
                      labelText: 'Blood Type', border: OutlineInputBorder()),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => bloodTypeController.text = v ?? '',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: smokingStatus,
                  decoration: const InputDecoration(
                      labelText: 'Smoking Status',
                      border: OutlineInputBorder()),
                  items: ['never', 'former', 'current']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => smokingStatus = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: alcoholUse,
                  decoration: const InputDecoration(
                      labelText: 'Alcohol Use', border: OutlineInputBorder()),
                  items: ['none', 'occasional', 'moderate', 'heavy']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => alcoholUse = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: exerciseFrequency,
                  decoration: const InputDecoration(
                      labelText: 'Exercise Frequency',
                      border: OutlineInputBorder()),
                  items: ['none', 'rarely', 'weekly', 'daily']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => exerciseFrequency = v),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.organDonor),
                  value: organDonor,
                  onChanged: (v) => setDialogState(() => organDonor = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emergencyNotesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Emergency Notes',
                      border: OutlineInputBorder(),
                      hintText: 'Critical info for emergencies...'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await apiService.updateMedicalRecord({
                          'blood_type': bloodTypeController.text.isEmpty
                              ? null
                              : bloodTypeController.text,
                          'height_cm': heightController.text.isEmpty
                              ? null
                              : double.tryParse(heightController.text),
                          'weight_kg': weightController.text.isEmpty
                              ? null
                              : double.tryParse(weightController.text),
                          'smoking_status': smokingStatus,
                          'alcohol_use': alcoholUse,
                          'exercise_frequency': exerciseFrequency,
                          'organ_donor': organDonor,
                          'emergency_notes':
                              emergencyNotesController.text.isEmpty
                                  ? null
                                  : emergencyNotesController.text,
                        });
                        if (mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddConditionDialog() {
    final nameController = TextEditingController();
    final treatmentController = TextEditingController();
    final notesController = TextEditingController();
    String? category;
    String severity = 'mild';
    DateTime? diagnosedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Medical Condition',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Condition Name *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Type 2 Diabetes'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: [
                    'cardiovascular',
                    'respiratory',
                    'digestive',
                    'neurological',
                    'musculoskeletal',
                    'endocrine',
                    'mental_health',
                    'skin',
                    'infectious',
                    'other'
                  ]
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.replaceAll('_', ' ').toUpperCase())))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(
                      labelText: 'Severity', border: OutlineInputBorder()),
                  items: ['mild', 'moderate', 'severe']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1))))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => severity = v ?? 'mild'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null)
                      setDialogState(() => diagnosedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Diagnosed Date',
                        border: OutlineInputBorder()),
                    child: Text(diagnosedDate != null
                        ? '${diagnosedDate!.day}/${diagnosedDate!.month}/${diagnosedDate!.year}'
                        : 'Select date'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: treatmentController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Treatment',
                      border: OutlineInputBorder(),
                      hintText: 'Current treatment plan...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Notes', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name is required')));
                        return;
                      }
                      try {
                        await apiService.addMedicalCondition({
                          'name': nameController.text,
                          'category': category,
                          'severity': severity,
                          'diagnosed_date':
                              diagnosedDate?.toIso8601String().split('T')[0],
                          'treatment': treatmentController.text.isEmpty
                              ? null
                              : treatmentController.text,
                          'notes': notesController.text.isEmpty
                              ? null
                              : notesController.text,
                        });
                        if (mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Add Condition'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAllergyDialog() {
    final allergenController = TextEditingController();
    final reactionController = TextEditingController();
    String? category;
    String severity = 'mild';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Allergy',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: allergenController,
                  decoration: const InputDecoration(
                      labelText: 'Allergen *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Penicillin, Peanuts'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: [
                    'drug',
                    'food',
                    'environmental',
                    'insect',
                    'latex',
                    'other'
                  ]
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(
                      labelText: 'Severity *', border: OutlineInputBorder()),
                  items: ['mild', 'moderate', 'severe', 'life_threatening']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.replaceAll('_', ' ').toUpperCase())))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => severity = v ?? 'mild'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reactionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Reaction Description',
                      border: OutlineInputBorder(),
                      hintText: 'Describe what happens...'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (allergenController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Allergen is required')));
                        return;
                      }
                      try {
                        await apiService.addMedicalAllergy({
                          'allergen': allergenController.text,
                          'category': category,
                          'severity': severity,
                          'reaction': reactionController.text.isEmpty
                              ? null
                              : reactionController.text,
                        });
                        if (mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Add Allergy'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final prescribedForController = TextEditingController();
    String? route;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Medication',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Medication Name *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Metformin'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dosageController,
                        decoration: const InputDecoration(
                            labelText: 'Dosage',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 500mg'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: frequencyController,
                        decoration: const InputDecoration(
                            labelText: 'Frequency',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., twice daily'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: route,
                  decoration: const InputDecoration(
                      labelText: 'Route', border: OutlineInputBorder()),
                  items: [
                    'oral',
                    'injection',
                    'topical',
                    'inhaled',
                    'sublingual',
                    'other'
                  ]
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => route = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prescribedForController,
                  decoration: const InputDecoration(
                      labelText: 'Prescribed For',
                      border: OutlineInputBorder(),
                      hintText: 'Reason for taking this medication'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name is required')));
                        return;
                      }
                      try {
                        await apiService.addMedicalMedication({
                          'name': nameController.text,
                          'dosage': dosageController.text.isEmpty
                              ? null
                              : dosageController.text,
                          'frequency': frequencyController.text.isEmpty
                              ? null
                              : frequencyController.text,
                          'route': route,
                          'prescribed_for': prescribedForController.text.isEmpty
                              ? null
                              : prescribedForController.text,
                          'start_date':
                              DateTime.now().toIso8601String().split('T')[0],
                          'is_active': true,
                        });
                        if (mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Add Medication'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSurgeryDialog() {
    final procedureController = TextEditingController();
    final surgeonController = TextEditingController();
    final hospitalController = TextEditingController();
    final outcomeController = TextEditingController();
    String? procedureType;
    DateTime? surgeryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Surgery',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: procedureController,
                  decoration: const InputDecoration(
                      labelText: 'Procedure Name *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Appendectomy'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: procedureType,
                  decoration: const InputDecoration(
                      labelText: 'Procedure Type',
                      border: OutlineInputBorder()),
                  items: [
                    'emergency',
                    'elective',
                    'outpatient',
                    'inpatient',
                    'minimally_invasive'
                  ]
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.replaceAll('_', ' ').toUpperCase())))
                      .toList(),
                  onChanged: (v) => setDialogState(() => procedureType = v),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setDialogState(() => surgeryDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Surgery Date',
                        border: OutlineInputBorder()),
                    child: Text(surgeryDate != null
                        ? '${surgeryDate!.day}/${surgeryDate!.month}/${surgeryDate!.year}'
                        : 'Select date'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: surgeonController,
                  decoration: const InputDecoration(
                      labelText: 'Surgeon Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalController,
                  decoration: const InputDecoration(
                      labelText: 'Hospital/Clinic',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: outcomeController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Outcome',
                      border: OutlineInputBorder(),
                      hintText: 'Surgery outcome and recovery notes'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (procedureController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Procedure name is required')));
                        return;
                      }
                      try {
                        await apiService.addMedicalSurgery({
                          'procedure_name': procedureController.text,
                          'procedure_type': procedureType,
                          'surgery_date':
                              surgeryDate?.toIso8601String().split('T')[0],
                          'surgeon_name': surgeonController.text.isEmpty
                              ? null
                              : surgeonController.text,
                          'hospital_name': hospitalController.text.isEmpty
                              ? null
                              : hospitalController.text,
                          'outcome': outcomeController.text.isEmpty
                              ? null
                              : outcomeController.text,
                        });
                        if (mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Add Surgery'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddVaccinationDialog() {
    final vaccineNameController = TextEditingController();
    final administeredByController = TextEditingController();
    final locationController = TextEditingController();
    String? vaccineType;
    int doseNumber = 1;
    int totalDoses = 1;
    DateTime? administeredDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Vaccination',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: vaccineNameController,
                  decoration: const InputDecoration(
                      labelText: 'Vaccine Name *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., COVID-19 Pfizer'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: vaccineType,
                  decoration: const InputDecoration(
                      labelText: 'Vaccine Type', border: OutlineInputBorder()),
                  items: [
                    'childhood',
                    'adult',
                    'travel',
                    'flu',
                    'covid',
                    'booster',
                    'other'
                  ]
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e[0].toUpperCase() + e.substring(1))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => vaccineType = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: doseNumber,
                        decoration: const InputDecoration(
                            labelText: 'Dose #', border: OutlineInputBorder()),
                        items: [1, 2, 3, 4, 5]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text('$e')))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => doseNumber = v ?? 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: totalDoses,
                        decoration: const InputDecoration(
                            labelText: 'Total Doses',
                            border: OutlineInputBorder()),
                        items: [1, 2, 3, 4, 5]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text('$e')))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => totalDoses = v ?? 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null)
                      setDialogState(() => administeredDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Administered Date',
                        border: OutlineInputBorder()),
                    child: Text(administeredDate != null
                        ? '${administeredDate!.day}/${administeredDate!.month}/${administeredDate!.year}'
                        : 'Select date'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: administeredByController,
                  decoration: const InputDecoration(
                      labelText: 'Administered By',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      hintText: 'Hospital/Clinic name'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (vaccineNameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Vaccine name is required')));
                        return;
                      }
                      try {
                        await apiService.addMedicalVaccination({
                          'vaccine_name': vaccineNameController.text,
                          'vaccine_type': vaccineType,
                          'dose_number': doseNumber,
                          'total_doses': totalDoses,
                          'administered_date':
                              administeredDate?.toIso8601String().split('T')[0],
                          'administered_by':
                              administeredByController.text.isEmpty
                                  ? null
                                  : administeredByController.text,
                          'location': locationController.text.isEmpty
                              ? null
                              : locationController.text,
                        });
                        if (mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Add Vaccination'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentDetails(Map<String, dynamic> doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _DocumentDetailsSheet(
          document: doc,
          onAIConsult: () {
            Navigator.pop(context);
            _openDocumentAIConsultation(doc);
          },
        ),
      ),
    );
  }

  void _openDocumentAIConsultation(Map<String, dynamic> doc) {
    showLiveAICallBottomSheet(
      context: context,
      config: LiveAICallConfig(
        specialist: 'physician',
        patientContext:
            'User wants to discuss a medical document:\n\nDocument: ${doc['title']}\nType: ${doc['document_type']}\nDate: ${doc['document_date']}\n\nAI Analysis:\n${doc['ai_analysis'] ?? 'Not analyzed yet'}\n\nHelp explain this document and answer any questions.',
      ),
    );
  }

  Future<void> _deleteAllergy(int id) async {
    try {
      await apiService.deleteMedicalAllergy(id);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _DocumentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onAIConsult;

  const _DocumentDetailsSheet({
    required this.document,
    required this.onAIConsult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(document['title'] ?? '',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                '${document['document_type']?.replaceAll('_', ' ').toUpperCase()} • ${document['document_date']}',
                style: TextStyle(color: Colors.grey[600])),

            if (document['doctor_name'] != null ||
                document['hospital_name'] != null) ...[
              const SizedBox(height: 16),
              if (document['doctor_name'] != null)
                Text('Doctor: ${document['doctor_name']}'),
              if (document['hospital_name'] != null)
                Text('Hospital: ${document['hospital_name']}'),
            ],

            if (document['description'] != null) ...[
              const SizedBox(height: 16),
              Text('Description',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              MarkdownText(data: document['description']),
            ],

            // AI Analysis
            if (document['ai_analysis'] != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.purple.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('AI Analysis',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MarkdownText(data: document['ai_analysis']),
                  ],
                ),
              ),
            ],

            // Images
            if (document['images'] != null &&
                (document['images'] as List).isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Attached Images',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (document['images'] as List).length,
                  itemBuilder: (context, index) {
                    final img = document['images'][index];
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: img['image_url'] != null
                            ? DecorationImage(
                                image: NetworkImage(img['image_url']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: img['image_url'] == null
                          ? const Center(
                              child: Icon(Icons.image,
                                  size: 40, color: Colors.grey))
                          : null,
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAIConsult,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Discuss with AI'),
                style:
                    ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
