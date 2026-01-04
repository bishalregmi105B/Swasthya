import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class MedicineDeliveryScreen extends StatefulWidget {
  const MedicineDeliveryScreen({super.key});

  @override
  State<MedicineDeliveryScreen> createState() => _MedicineDeliveryScreenState();
}

class _MedicineDeliveryScreenState extends State<MedicineDeliveryScreen> {
  List<dynamic> _medicines = [];
  List<dynamic> _pharmacies = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final medicinesData = await apiService.getMedicines();
      final pharmaciesData = await apiService.getPharmacies();
      final categoriesData = await apiService.getMedicineCategories();

      // Cache for offline use
      await OfflineCacheService.cacheData('medicines', medicinesData);
      await OfflineCacheService.cachePharmacies(List<Map<String, dynamic>>.from(
          pharmaciesData.map((e) => Map<String, dynamic>.from(e))));

      setState(() {
        _medicines = medicinesData['medicines'] ?? [];
        _pharmacies = pharmaciesData;
        _categories = categoriesData;
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache on error
      final cachedMedicines = OfflineCacheService.getCachedData('medicines');
      final cachedPharmacies = OfflineCacheService.getCachedPharmacies();

      if (cachedMedicines != null || cachedPharmacies != null) {
        setState(() {
          _medicines = cachedMedicines?['medicines'] ?? [];
          _pharmacies = cachedPharmacies ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredMedicines {
    var list = _medicines;
    if (_selectedCategory != 'all') {
      list = list
          .where((m) =>
              (m['category'] ?? '').toString().toLowerCase() ==
              _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((m) =>
              (m['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (m['generic_name'] ?? '')
                  .toString()
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
      appBar: AppBar(
        title: Text(l10n.medicineDelivery),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: l10n.search,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                      ),
                    ),

                    // AI Pharmacist Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/chats'),
                        child: Row(
                          children: [
                            const Icon(Icons.smart_toy,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(l10n.askAIPharmacist,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Chips
                    _buildCategoryChips(),
                    const SizedBox(height: 16),

                    // Medicines Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.popularProducts,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_filteredMedicines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.medication,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No medicines found'),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredMedicines.length,
                          itemBuilder: (context, index) {
                            final medicine = _filteredMedicines[index];
                            return _buildMedicineCard(medicine, l10n, isDark);
                          },
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Pharmacies Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.partneredPharmacies,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._pharmacies.take(5).map(
                        (pharmacy) => _buildPharmacyCard(pharmacy, isDark)),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat['name'] ?? ''),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat['id']),
              selectedColor: AppColors.primary.withOpacity(0.2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicineCard(
      Map<String, dynamic> medicine, AppLocalizations l10n, bool isDark) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: medicine['image_url'] != null
                ? ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      medicine['image_url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.medication,
                            color: AppColors.primary, size: 40),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.medication,
                        color: AppColors.primary, size: 40),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FDA Badge
                if (medicine['is_fda_approved'] == true)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('FDA',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                Text(
                  medicine['name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  medicine['strength'] ?? medicine['form'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Rs. ${medicine['price'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    if (medicine['rating'] != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text('${medicine['rating']}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Add to cart logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${medicine['name']} added to cart')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(l10n.addToCart,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> pharmacy, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        onTap: () => context.push('/pharmacy/${pharmacy['id']}'),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_pharmacy, color: Colors.green),
        ),
        title: Text(
          pharmacy['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            if (pharmacy['rating'] != null) ...[
              const Icon(Icons.star, size: 14, color: Colors.amber),
              Text(' ${pharmacy['rating']}',
                  style: const TextStyle(fontSize: 12)),
              const Text(' • ', style: TextStyle(fontSize: 12)),
            ],
            Text(pharmacy['delivery_time'] ?? '',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pharmacy['is_verified'] == true)
              const Icon(Icons.verified, color: Colors.blue, size: 18),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
