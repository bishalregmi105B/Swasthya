import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<dynamic> _contacts = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final data = await apiService.getEmergencyContacts();

      // Cache for critical offline access
      await OfflineCacheService.cacheEmergencyContacts(
          List<Map<String, dynamic>>.from((data['contacts'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))));

      setState(() {
        _contacts = data['contacts'] ?? [];
        _isLoading = false;
        _isOffline = false;
      });
    } catch (e) {
      // CRITICAL: Emergency contacts must work offline
      final cachedContacts = OfflineCacheService.getCachedEmergencyContacts();
      setState(() {
        _contacts = cachedContacts ?? _getDefaultEmergencyContacts();
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  List<Map<String, dynamic>> _getDefaultEmergencyContacts() {
    // Always available emergency numbers
    return [
      {'name': 'Ambulance', 'phone': '102', 'type': 'emergency'},
      {'name': 'Police', 'phone': '100', 'type': 'emergency'},
      {'name': 'Fire', 'phone': '101', 'type': 'emergency'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emergencyServices),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.red.shade900, Colors.orange.shade700]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(color: Colors.red.withOpacity(0.2)),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            size: 32, color: Colors.white),
                        const SizedBox(height: 8),
                        const Text('Current Location',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        Text('Kathmandu, Nepal',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SOS Button
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton(
                onPressed: () => _makeCall('102'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emergency, size: 32, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('${l10n.sos} - CALL 102',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Dial Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickDial(context, l10n.ambulance, '102',
                    Icons.airport_shuttle, Colors.red),
                _buildQuickDial(context, l10n.police, '100', Icons.local_police,
                    Colors.blue),
                _buildQuickDial(context, l10n.fireDept, '101',
                    Icons.local_fire_department, Colors.orange),
                _buildQuickDial(context, l10n.poisonControl, '1066',
                    Icons.warning, Colors.purple),
              ],
            ),

            const SizedBox(height: 24),

            // Chat with Doctor
            Text(l10n.aiTriage,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/chats'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.blue.withOpacity(0.1)
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.medical_services,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chat with Doctor',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Connect with a specialist for consultation',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Emergency Contacts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.emergencyContacts,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _showAddContactDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addContact),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.contacts,
                        size: 48, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('No emergency contacts',
                        style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: _showAddContactDialog,
                        child: const Text('Add Contact')),
                  ],
                ),
              )
            else
              ..._contacts.map((c) => _buildContact(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDial(BuildContext context, String title, String number,
      IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _makeCall(number),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(number,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildContact(BuildContext context, dynamic contact) {
    final isPrimary = contact['is_primary'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              (contact['name'] ?? 'C')[0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(contact['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('Primary',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                Text(
                  contact['relationship'] ?? '',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.primary),
            onPressed: () => _makeCall(contact['phone']),
          ),
        ],
      ),
    );
  }

  void _makeCall(String? phone) async {
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open dialer for $phone')),
          );
        }
      }
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String relationship = 'spouse';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addEmergencyContact),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Name', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                  labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: [
                'spouse',
                'father',
                'mother',
                'sibling',
                'friend',
                'other'
              ]
                  .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r[0].toUpperCase() + r.substring(1))))
                  .toList(),
              onChanged: (v) => relationship = v ?? 'spouse',
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                try {
                  await apiService.addEmergencyContact(
                    nameController.text,
                    phoneController.text,
                    relationship,
                  );
                  Navigator.pop(context);
                  _loadContacts();
                } catch (e) {}
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
