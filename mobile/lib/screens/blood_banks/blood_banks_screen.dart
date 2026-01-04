import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class BloodBanksScreen extends StatefulWidget {
  const BloodBanksScreen({super.key});

  @override
  State<BloodBanksScreen> createState() => _BloodBanksScreenState();
}

class _BloodBanksScreenState extends State<BloodBanksScreen> {
  List<dynamic> _bloodBanks = [];
  List<dynamic> _ngos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await apiService.getBloodBanks();
      final all = data['blood_banks'] ?? [];

      // Cache the data for offline use
      await OfflineCacheService.cacheBloodBanks(List<Map<String, dynamic>>.from(
          all.map((e) => Map<String, dynamic>.from(e))));

      setState(() {
        _bloodBanks = all.where((b) => b['type'] == 'blood_bank').toList();
        _ngos = all.where((b) => b['type'] == 'ngo').toList();
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache
      final cachedData = OfflineCacheService.getCachedBloodBanks();
      if (cachedData != null && cachedData.isNotEmpty) {
        setState(() {
          _bloodBanks =
              cachedData.where((b) => b['type'] == 'blood_bank').toList();
          _ngos = cachedData.where((b) => b['type'] == 'ngo').toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.bloodBanks),
          bottom: TabBar(
            tabs: [Tab(text: l10n.bloodBanks), Tab(text: l10n.ngoDirectory)],
            indicatorColor: AppColors.primary,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBloodBanksList(context, l10n),
                  _buildNGOList(context, l10n),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: Colors.red,
          icon: const Icon(Icons.water_drop, color: Colors.white),
          label: Text(l10n.donate, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildBloodBanksList(BuildContext context, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Recommendation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.15),
                  Colors.orange.withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Recommendation',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(
                        'Based on your blood type, Nepal Red Cross is the nearest 24/7 center.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_bloodBanks.isEmpty)
            Center(
                child: Text('No blood banks found',
                    style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.5))))
          else
            ..._bloodBanks
                .map((bank) => _buildBloodBankCard(context, l10n, bank)),
        ],
      ),
    );
  }

  Widget _buildBloodBankCard(
      BuildContext context, AppLocalizations l10n, dynamic bank) {
    final isOpen = bank['is_open'] ?? false;
    final is24h = bank['is_open_24h'] ?? false;
    final availability =
        bank['blood_availability'] as Map<String, dynamic>? ?? {};
    final availableTypes = availability.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bank['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      '${bank['address'] ?? ''}, ${bank['city'] ?? ''}',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          (isOpen ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOpen ? l10n.openNow : l10n.closed,
                      style: TextStyle(
                          fontSize: 12,
                          color: isOpen ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (is24h) ...[
                    const SizedBox(height: 4),
                    Text('24/7',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ],
          ),
          if (bank['rating'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${bank['rating']}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (availableTypes.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: availableTypes
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(bank['phone']),
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text(l10n.callNow),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openMap(bank['latitude'], bank['longitude']),
                  icon: const Icon(Icons.directions, size: 18),
                  label: Text(l10n.navigate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNGOList(BuildContext context, AppLocalizations l10n) {
    if (_ngos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism,
                size: 64, color: Colors.pink.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No NGOs found',
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.5))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ngos.length,
        itemBuilder: (context, index) {
          final ngo = _ngos[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.volunteer_activism, color: Colors.pink),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ngo['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${ngo['address'] ?? ''}, ${ngo['city'] ?? ''}',
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
                  icon: const Icon(Icons.phone, color: Colors.pink),
                  onPressed: () => _makeCall(ngo['phone']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _makeCall(String? phone) async {
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // Silent fail
      }
    }
  }

  void _openMap(double? lat, double? lng) async {
    if (lat != null && lng != null) {
      final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // Silent fail
      }
    }
  }
}
