import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

/// Disease Encyclopedia Screen - Search and browse diseases
class DiseaseSearchScreen extends StatefulWidget {
  const DiseaseSearchScreen({super.key});

  @override
  State<DiseaseSearchScreen> createState() => _DiseaseSearchScreenState();
}

class _DiseaseSearchScreenState extends State<DiseaseSearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _categories = [];
  List<dynamic> _commonDiseases = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCommonDiseases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await apiService.getDiseaseCategories();
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

  Future<void> _loadCommonDiseases() async {
    try {
      final data = await apiService.getCommonDiseases();
      final diseases = data['diseases'] ?? [];

      // Cache for offline use
      await OfflineCacheService.cacheCommonDiseases(
          List<Map<String, dynamic>>.from(
              diseases.map((e) => Map<String, dynamic>.from(e))));

      if (mounted) {
        setState(() => _commonDiseases = diseases);
      }
    } catch (e) {
      // Try loading from cache
      final cached = OfflineCacheService.getCachedCommonDiseases();
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() => _commonDiseases = cached);
      }
    }
  }

  Future<void> _search(String query) async {
    if (query.length < 2) return;

    setState(() => _isLoading = true);
    try {
      final data = await apiService.searchDiseases(query);
      final results = data['results'] ?? [];

      // Cache search results for offline use
      await OfflineCacheService.cacheDiseaseSearch(
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
      final cached = OfflineCacheService.getCachedDiseaseSearch(query);
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

  Future<void> _loadByCategory(String categoryId) async {
    setState(() {
      _selectedCategory = categoryId;
      _isLoading = true;
    });
    try {
      final data = await apiService.getDiseasesByCategory(categoryId);
      if (mounted) {
        setState(() {
          _searchResults = data['results'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diseaseEncyclopedia),
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
                hintText: l10n.searchDiseases,
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
                            onSelected: (_) => _loadByCategory(cat['id']),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],

          // Results or common diseases
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                    ? _buildResultsList()
                    : _buildCommonDiseases(l10n),
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
        final disease = _searchResults[index];
        return _buildDiseaseCard(disease);
      },
    );
  }

  Widget _buildCommonDiseases(AppLocalizations l10n) {
    if (_commonDiseases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_information,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.searchOrSelectCategory,
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
          l10n.commonDiseases,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ..._commonDiseases.map((d) => _buildDiseaseCard(d)),
      ],
    );
  }

  Widget _buildDiseaseCard(Map<String, dynamic> disease) {
    final icdCodes =
        (disease['icd10_codes'] as List?)?.take(2).join(', ') ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.coronavirus, color: Colors.blue),
        ),
        title: Text(
          disease['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: icdCodes.isNotEmpty
            ? Text('ICD-10: $icdCodes', style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context
            .push('/disease-info/${Uri.encodeComponent(disease['name'])}'),
      ),
    );
  }
}
