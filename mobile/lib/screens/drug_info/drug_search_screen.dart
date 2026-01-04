import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

/// Drug Search Screen - Search and browse medicines
class DrugSearchScreen extends StatefulWidget {
  const DrugSearchScreen({super.key});

  @override
  State<DrugSearchScreen> createState() => _DrugSearchScreenState();
}

class _DrugSearchScreenState extends State<DrugSearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _categories = [];
  List<dynamic> _commonDrugs = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCommonDrugs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await apiService.getDrugCategories();
      if (mounted) {
        setState(() {
          _categories = data['categories'] ?? [];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadCommonDrugs() async {
    try {
      final data = await apiService.getCommonDrugs();
      final drugs = data['medicines'] ?? [];

      // Cache for offline use
      await OfflineCacheService.cacheCommonDrugs(
          List<Map<String, dynamic>>.from(
              drugs.map((e) => Map<String, dynamic>.from(e))));

      if (mounted) {
        setState(() => _commonDrugs = drugs);
      }
    } catch (e) {
      // Try loading from cache
      final cached = OfflineCacheService.getCachedCommonDrugs();
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() => _commonDrugs = cached);
      }
    }
  }

  Future<void> _search(String query) async {
    if (query.length < 2) return;

    setState(() => _isLoading = true);
    try {
      final data = await apiService.searchDrugs(query);
      final results = data['results'] ?? [];

      // Cache search results for offline use
      await OfflineCacheService.cacheDrugSearch(
          query,
          List<Map<String, dynamic>>.from(
              results.map((e) => Map<String, dynamic>.from(e))));

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Try loading from cache
      final cached = OfflineCacheService.getCachedDrugSearch(query);
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() {
          _searchResults = cached;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicineDatabase),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchMedicines,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _search(value);
                } else if (value.isEmpty) {
                  setState(() => _searchResults = []);
                }
              },
            ),
          ),

          // Categories
          if (_searchResults.isEmpty && !_isLoading) ...[
            SizedBox(
              height: 50,
              child: _isLoadingCategories
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['id'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text('${cat['icon']} ${cat['name']}'),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedCategory = cat['id']);
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],

          // Results or common drugs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                    ? _buildResultsList()
                    : _buildCommonDrugs(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final drug = _searchResults[index];
        return _buildDrugCard(drug);
      },
    );
  }

  Widget _buildCommonDrugs(AppLocalizations l10n) {
    if (_commonDrugs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.searchMedicines,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.commonMedicines,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ..._commonDrugs.map((d) => _buildDrugCard(d)),
      ],
    );
  }

  Widget _buildDrugCard(Map<String, dynamic> drug) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medication, color: Colors.purple),
        ),
        title: Text(
          drug['brand_name'] ?? drug['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: drug['generic_name'] != null
            ? Text(drug['generic_name'], style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final name = drug['brand_name'] ?? drug['name'] ?? 'Unknown';
          context.push('/drug-detail/${Uri.encodeComponent(name)}');
        },
      ),
    );
  }
}
