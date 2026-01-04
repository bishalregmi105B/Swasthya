import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _hospitals = [];
  List<dynamic> _pharmacies = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  String _searchQuery = '';
  bool _showOpen24h = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hospitalsData = await apiService.getHospitals();
      final pharmaciesList = await apiService.getPharmacies();

      final hospitals = (hospitalsData['hospitals'] ?? [])
          .map((h) => {
                ...h,
                'facility_type': h['type'] ?? 'hospital',
              })
          .toList();
      final pharmacies = pharmaciesList
          .map((p) => {
                ...p,
                'facility_type': 'pharmacy',
              })
          .toList();

      // Cache the data for offline use
      await OfflineCacheService.cacheHospitals(List<Map<String, dynamic>>.from(
          hospitals.map((e) => Map<String, dynamic>.from(e))));
      await OfflineCacheService.cachePharmacies(List<Map<String, dynamic>>.from(
          pharmacies.map((e) => Map<String, dynamic>.from(e))));

      setState(() {
        _hospitals = hospitals;
        _pharmacies = pharmacies;
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache
      final cachedHospitals = OfflineCacheService.getCachedHospitals();
      final cachedPharmacies = OfflineCacheService.getCachedPharmacies();

      if ((cachedHospitals != null && cachedHospitals.isNotEmpty) ||
          (cachedPharmacies != null && cachedPharmacies.isNotEmpty)) {
        setState(() {
          _hospitals = cachedHospitals ?? [];
          _pharmacies = cachedPharmacies ?? [];
          _isLoading = false;
          _error = null; // Clear error since we have cached data
        });
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredHospitals {
    var list = _hospitals;
    if (_showOpen24h) {
      list = list.where((f) => f['is_open_24h'] == true).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((f) => (f['name'] ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  List<dynamic> get _filteredPharmacies {
    var list = _pharmacies;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((f) => (f['name'] ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101822) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.nearbyFacilities),
        backgroundColor: isDark ? const Color(0xFF101822) : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF101822) : Colors.white,
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF282f39) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: Colors.grey.shade500),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: l10n.search,
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(l10n.open24Hours, _showOpen24h, (v) {
                        setState(() => _showOpen24h = v);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          l10n.hospitals, _tabController.index == 0, (v) {
                        _tabController.animateTo(0);
                        setState(() {});
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          l10n.pharmacies, _tabController.index == 1, (v) {
                        _tabController.animateTo(1);
                        setState(() {});
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Segmented Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1c2431) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorPadding: const EdgeInsets.all(3),
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDark ? Colors.grey.shade500 : Colors.grey.shade700,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: '${l10n.hospitals} (${_filteredHospitals.length})'),
                Tab(text: '${l10n.pharmacies} (${_filteredPharmacies.length})'),
              ],
            ),
          ),

          // Results Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Nearby Results',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_tabController.index == 0 ? _filteredHospitals.length : _filteredPharmacies.length} found',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),

          // Facility List - Full Screen
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFacilityList(_filteredHospitals, l10n),
                          _buildFacilityList(_filteredPharmacies, l10n),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/chats'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        label: const Text('Ask AI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          const Text('Failed to load facilities',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, Function(bool) onSelected) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : const Color(0xFF282f39).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.3), blurRadius: 10)
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityList(List<dynamic> facilities, AppLocalizations l10n) {
    if (facilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text('No facilities found',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: facilities.length,
        itemBuilder: (context, index) {
          final facility = facilities[index];
          final isTopRated = (facility['ai_trust_score'] ?? 0) >= 9;
          return _buildFacilityCard(facility, l10n, isTopRated: isTopRated);
        },
      ),
    );
  }

  Widget _buildFacilityCard(dynamic facility, AppLocalizations l10n,
      {bool isTopRated = false}) {
    final type = facility['facility_type'] ?? 'hospital';
    final isOpen = facility['is_open'] ?? facility['is_open_24h'] ?? false;
    final rating = (facility['rating'] ?? 0).toDouble();

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'hospital':
        icon = Icons.local_hospital;
        iconColor = AppColors.primary;
        break;
      case 'pharmacy':
        icon = Icons.medication;
        iconColor = Colors.green;
        break;
      case 'clinic':
        icon = Icons.medical_services;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.local_hospital;
        iconColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () {
        if (type == 'hospital' || type == 'clinic') {
          context.push('/hospital/${facility['id']}');
        } else if (type == 'pharmacy') {
          context.push('/pharmacy/${facility['id']}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isTopRated
              ? const Color(0xFF1c232d)
              : const Color(0xFF1c232d).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTopRated
                ? AppColors.primary.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Match Badge
            if (isTopRated)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('AI MATCH',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility['name'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            facility['city'] ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                          Text(' • ',
                              style: TextStyle(color: Colors.grey.shade600)),
                          Text(
                            type.toString().substring(0, 1).toUpperCase() +
                                type.toString().substring(1),
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                          Text(' • ',
                              style: TextStyle(color: Colors.grey.shade600)),
                          Text(
                            isOpen
                                ? (facility['is_open_24h'] == true
                                    ? 'Open 24h'
                                    : l10n.openNow)
                                : l10n.closed,
                            style: TextStyle(
                              color:
                                  isOpen ? Colors.green : Colors.red.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Rating Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$rating',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openMap(facility['latitude'], facility['longitude']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Navigate',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: IconButton(
                    onPressed: () => _makeCall(facility['phone']),
                    icon: const Icon(Icons.call, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (type == 'hospital' || type == 'clinic') {
                        context.push('/hospital/${facility['id']}');
                      } else if (type == 'pharmacy') {
                        context.push('/pharmacy/${facility['id']}');
                      }
                    },
                    icon: const Icon(Icons.info_outline,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  void _makeCall(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // Silent fail
      }
    }
  }
}
