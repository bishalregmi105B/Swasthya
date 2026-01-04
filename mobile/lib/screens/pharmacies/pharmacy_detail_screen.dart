import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class PharmacyDetailScreen extends StatefulWidget {
  final int pharmacyId;

  const PharmacyDetailScreen({super.key, required this.pharmacyId});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  Map<String, dynamic>? _pharmacy;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await apiService.getPharmacy(widget.pharmacyId);
      setState(() {
        _pharmacy = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_pharmacy == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Pharmacy not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or gradient
                  _pharmacy!['image_url'] != null
                      ? Image.network(
                          _pharmacy!['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildGradientHeader(),
                        )
                      : _buildGradientHeader(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8)
                        ],
                      ),
                    ),
                  ),
                  // Info
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_pharmacy!['is_verified'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('Verified',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _pharmacy!['is_open'] == true
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _pharmacy!['is_open'] == true
                                    ? l10n.openNow
                                    : l10n.closed,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pharmacy!['name'] ?? 'Pharmacy',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _pharmacy!['city'] ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  Row(
                    children: [
                      _buildStatCard('${_pharmacy!['rating'] ?? 'N/A'}',
                          'Rating', Icons.star, Colors.amber),
                      const SizedBox(width: 10),
                      _buildStatCard('${_pharmacy!['total_reviews'] ?? 0}',
                          l10n.reviews, Icons.rate_review, Colors.blue),
                      const SizedBox(width: 10),
                      _buildStatCard(_pharmacy!['delivery_time'] ?? 'N/A',
                          'Delivery', Icons.delivery_dining, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Delivery Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C2027) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery Information',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.delivery_dining,
                            'Delivery Time: ${_pharmacy!['delivery_time'] ?? 'N/A'}'),
                        if (_pharmacy!['delivery_fee'] != null)
                          _buildInfoRow(Icons.paid,
                              'Delivery Fee: Rs. ${_pharmacy!['delivery_fee']}'),
                        if (_pharmacy!['free_delivery_above'] != null)
                          _buildInfoRow(Icons.local_offer,
                              'Free delivery above Rs. ${_pharmacy!['free_delivery_above']}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contact
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C2027) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            Icons.location_on, _pharmacy!['address'] ?? 'N/A'),
                        if (_pharmacy!['phone'] != null)
                          InkWell(
                            onTap: () => _makeCall(_pharmacy!['phone']),
                            child: _buildInfoRow(
                                Icons.phone, _pharmacy!['phone'],
                                isClickable: true),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Order Medicines Button
                  ElevatedButton.icon(
                    onPressed: () => context.push('/medicine-delivery'),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Order Medicines'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(_pharmacy!['phone']),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final lat = _pharmacy!['latitude'];
                    final lng = _pharmacy!['longitude'];
                    if (lat != null && lng != null) {
                      _openMap(lat, lng);
                    }
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.teal.shade600],
        ),
      ),
      child: const Icon(Icons.medication, size: 64, color: Colors.white54),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isClickable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: isClickable ? AppColors.primary : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13, color: isClickable ? AppColors.primary : null),
            ),
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
        // Silent fail
      }
    }
  }

  void _openMap(dynamic lat, dynamic lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Silent fail
    }
  }
}
