import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class SimulationsListScreen extends StatefulWidget {
  const SimulationsListScreen({super.key});

  @override
  State<SimulationsListScreen> createState() => _SimulationsListScreenState();
}

class _SimulationsListScreenState extends State<SimulationsListScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _simulations = [];
  List<dynamic> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await apiService.getSimulations();
      final simulations = data['simulations'] ?? [];

      // Cache the data for offline use
      await OfflineCacheService.cacheSimulations(
          List<Map<String, dynamic>>.from(
              simulations.map((e) => Map<String, dynamic>.from(e))));

      setState(() {
        _simulations = simulations;
        _categories = data['categories'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache
      final cachedSimulations = OfflineCacheService.getCachedSimulations();
      if (cachedSimulations != null && cachedSimulations.isNotEmpty) {
        setState(() {
          _simulations = cachedSimulations;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredSimulations {
    if (_selectedCategory == null) return _simulations;
    return _simulations
        .where((s) => s['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emergencyTraining),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(l10n.failedToLoad),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Featured Card
                      SliverToBoxAdapter(
                        child: _buildFeaturedCard(),
                      ),
                      // Categories
                      SliverToBoxAdapter(
                        child: _buildCategoriesRow(),
                      ),
                      // Simulations Grid
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildSimulationCard(
                                _filteredSimulations[index]),
                            childCount: _filteredSimulations.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFef4444), Color(0xFFdc2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🔥 MOST IMPORTANT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Adult CPR',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Learn life-saving chest compressions',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/cpr-simulation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Start Now',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text('Categories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length + 1, // +1 for "All"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip(
                    'All', null, Icons.apps, _selectedCategory == null);
              }
              final cat = _categories[index - 1];
              return _buildCategoryChip(
                cat['name'],
                cat['slug'],
                _getIconFromName(cat['icon']),
                _selectedCategory == cat['slug'],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoryChip(
      String name, String? slug, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = slug),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).iconTheme.color),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationCard(Map<String, dynamic> sim) {
    final color = _parseColor(sim['color'] ?? '#136dec');
    final difficulty = sim['difficulty'] ?? 'beginner';
    final slug = sim['slug'] ?? 'adult-cpr';

    return GestureDetector(
      onTap: () => context.push('/simulation/$slug'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon header
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                      child: Icon(_getIconFromName(sim['icon']),
                          color: color, size: 36)),
                  if (sim['is_featured'] == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('⭐', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sim['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sim['description'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.timer,
                            size: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text('${sim['duration_minutes'] ?? 5} min',
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.5))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(difficulty)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            difficulty[0].toUpperCase() +
                                difficulty.substring(1),
                            style: TextStyle(
                                fontSize: 9,
                                color: _getDifficultyColor(difficulty),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconFromName(String? name) {
    switch (name) {
      case 'favorite':
        return Icons.favorite;
      case 'child_care':
        return Icons.child_care;
      case 'emergency':
        return Icons.emergency;
      case 'healing':
        return Icons.healing;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'psychology':
        return Icons.psychology;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'apps':
        return Icons.apps;
      default:
        return Icons.school;
    }
  }
}
