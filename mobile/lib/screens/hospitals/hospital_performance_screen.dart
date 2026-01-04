import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';
import '../../widgets/review_widgets.dart';

class HospitalPerformanceScreen extends StatefulWidget {
  final int hospitalId;

  const HospitalPerformanceScreen({super.key, required this.hospitalId});

  @override
  State<HospitalPerformanceScreen> createState() =>
      _HospitalPerformanceScreenState();
}

class _HospitalPerformanceScreenState extends State<HospitalPerformanceScreen> {
  Map<String, dynamic>? _hospital;
  List<dynamic> _departments = [];
  List<dynamic> _metrics = [];
  List<dynamic> _reviews = [];
  List<dynamic> _gallery = [];
  List<dynamic> _services = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final hospitalData = await apiService.getHospital(widget.hospitalId);
      final metricsData =
          await apiService.getHospitalMetrics(widget.hospitalId);

      // Cache for offline use
      await OfflineCacheService.cacheData('hospital_${widget.hospitalId}', {
        'hospital': hospitalData,
        'metrics': metricsData,
      });

      setState(() {
        _hospital = hospitalData;
        _departments = hospitalData['departments'] ?? [];
        _metrics = metricsData['metrics'] ?? [];
        _reviews = hospitalData['reviews'] ?? [];
        _gallery = hospitalData['gallery'] ?? [];
        _services = hospitalData['services'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache on error
      final cachedData =
          OfflineCacheService.getCachedData('hospital_${widget.hospitalId}');
      if (cachedData != null) {
        final hospitalData = cachedData['hospital'] as Map<String, dynamic>?;
        final metricsData = cachedData['metrics'] as Map<String, dynamic>?;

        setState(() {
          _hospital = hospitalData;
          _departments = hospitalData?['departments'] ?? [];
          _metrics = metricsData?['metrics'] ?? [];
          _reviews = hospitalData?['reviews'] ?? [];
          _gallery = hospitalData?['gallery'] ?? [];
          _services = hospitalData?['services'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _allImages {
    List<String> images = [];
    // Add main images first
    if (_hospital?['banner_url'] != null) images.add(_hospital!['banner_url']);
    if (_hospital?['image_url'] != null) images.add(_hospital!['image_url']);
    // Add gallery images
    for (var img in _gallery) {
      if (img['image_url'] != null) images.add(img['image_url']);
    }
    return images;
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

    if (_hospital == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Hospital not found')),
      );
    }

    final images = _allImages;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image Slider Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Slider
                  if (images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.local_hospital,
                                size: 64, color: Colors.white54),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade900,
                            Colors.indigo.shade800
                          ],
                        ),
                      ),
                      child: const Icon(Icons.local_hospital,
                          size: 64, color: Colors.white54),
                    ),
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
                  // Page indicator
                  if (images.length > 1)
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            images.length,
                            (i) => Container(
                                  width: _currentImageIndex == i ? 20 : 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == i
                                        ? AppColors.primary
                                        : Colors.white54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                )),
                      ),
                    ),
                  // Hospital info overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_hospital!['ai_trust_score'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text('AI ${_hospital!['ai_trust_score']}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (_hospital!['is_verified'] == true)
                              const Icon(Icons.verified,
                                  color: Colors.blue, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hospital!['name'] ?? 'Hospital',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_hospital!['type']?.toString().toUpperCase() ?? ''} • ${_hospital!['city'] ?? ''}',
                          style: const TextStyle(color: Colors.white70),
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
                  // Quick Stats Row
                  _buildQuickStats(l10n),
                  const SizedBox(height: 20),

                  // Social Media Links
                  if (_hasSocialLinks()) ...[
                    _buildSocialMediaSection(isDark),
                    const SizedBox(height: 20),
                  ],

                  // Capacity Section
                  _buildCapacitySection(l10n, isDark),
                  const SizedBox(height: 20),

                  // Features & Amenities
                  if (_hospital!['features'] != null ||
                      _hospital!['parking_available'] == true ||
                      _hospital!['wheelchair_accessible'] == true) ...[
                    _buildFeaturesSection(l10n, isDark),
                    const SizedBox(height: 20),
                  ],

                  // Services
                  if (_services.isNotEmpty) ...[
                    _buildServicesSection(l10n, isDark),
                    const SizedBox(height: 20),
                  ],

                  // Departments
                  if (_departments.isNotEmpty) ...[
                    _buildDepartmentsSection(l10n, isDark),
                    const SizedBox(height: 20),
                  ],

                  // Payment & Insurance
                  if (_hospital!['payment_methods'] != null ||
                      _hospital!['insurance_accepted'] != null) ...[
                    _buildPaymentInsuranceSection(l10n, isDark),
                    const SizedBox(height: 20),
                  ],

                  // Contact Info
                  _buildContactSection(l10n, isDark),
                  const SizedBox(height: 20),

                  // Performance Metrics
                  if (_metrics.isNotEmpty) ...[
                    _buildMetricsSection(l10n, isDark),
                    const SizedBox(height: 20),
                  ],

                  // Reviews
                  _buildReviewsSection(l10n, isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(l10n),
    );
  }

  Widget _buildQuickStats(AppLocalizations l10n) {
    return Row(
      children: [
        _buildStatCard('${_hospital!['rating'] ?? 'N/A'}', 'Rating', Icons.star,
            Colors.amber),
        const SizedBox(width: 10),
        _buildStatCard('${_hospital!['total_reviews'] ?? 0}', l10n.reviews,
            Icons.rate_review, Colors.blue),
        const SizedBox(width: 10),
        _buildStatCard(
          _hospital!['is_open_24h'] == true ? '24h' : 'Open',
          'Status',
          Icons.access_time,
          _hospital!['is_open_24h'] == true ? Colors.green : Colors.orange,
        ),
      ],
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
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  bool _hasSocialLinks() {
    return _hospital!['facebook_url'] != null ||
        _hospital!['instagram_url'] != null ||
        _hospital!['twitter_url'] != null ||
        _hospital!['linkedin_url'] != null ||
        _hospital!['youtube_url'] != null ||
        _hospital!['website'] != null;
  }

  Widget _buildSocialMediaSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Connect With Us',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (_hospital!['website'] != null)
                _buildSocialButton(Icons.language, 'Website', Colors.blue,
                    _hospital!['website']),
              if (_hospital!['facebook_url'] != null)
                _buildSocialButton(Icons.facebook, 'Facebook',
                    const Color(0xFF1877F2), _hospital!['facebook_url']),
              if (_hospital!['instagram_url'] != null)
                _buildSocialButton(Icons.camera_alt, 'Instagram',
                    const Color(0xFFE4405F), _hospital!['instagram_url']),
              if (_hospital!['twitter_url'] != null)
                _buildSocialButton(Icons.alternate_email, 'Twitter',
                    const Color(0xFF1DA1F2), _hospital!['twitter_url']),
              if (_hospital!['linkedin_url'] != null)
                _buildSocialButton(Icons.work, 'LinkedIn',
                    const Color(0xFF0A66C2), _hospital!['linkedin_url']),
              if (_hospital!['youtube_url'] != null)
                _buildSocialButton(Icons.play_circle_fill, 'YouTube',
                    const Color(0xFFFF0000), _hospital!['youtube_url']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
      IconData icon, String label, Color color, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hospital Capacity',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildCapacityItem(
                  Icons.bed,
                  '${_hospital!['total_beds'] ?? 'N/A'}',
                  'Total Beds',
                  Colors.blue),
              _buildCapacityItem(Icons.emergency,
                  '${_hospital!['icu_beds'] ?? 'N/A'}', 'ICU Beds', Colors.red),
              _buildCapacityItem(
                  Icons.air,
                  '${_hospital!['ventilators'] ?? 'N/A'}',
                  'Ventilators',
                  Colors.purple),
              _buildCapacityItem(
                  Icons.medical_services,
                  '${_hospital!['operation_theaters'] ?? 'N/A'}',
                  'OT Rooms',
                  Colors.green),
              _buildCapacityItem(
                  Icons.local_taxi,
                  '${_hospital!['ambulances'] ?? 'N/A'}',
                  'Ambulances',
                  Colors.orange),
              _buildCapacityItem(
                  Icons.schedule,
                  '${_hospital!['avg_wait_time'] ?? 'N/A'} min',
                  'Wait Time',
                  Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityItem(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(AppLocalizations l10n, bool isDark) {
    List<String> features = [];
    if (_hospital!['features'] != null) {
      features = (_hospital!['features'] as List)
          .map((e) => e.toString().trim())
          .toList();
    }
    if (_hospital!['parking_available'] == true) features.add('Parking');
    if (_hospital!['wheelchair_accessible'] == true)
      features.add('Wheelchair Access');
    if (_hospital!['emergency_available'] == true) features.add('Emergency');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Features & Amenities',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features
                .map((f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      side:
                          BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Services',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2027) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getServiceIcon(service['category']),
                        color: AppColors.primary, size: 22),
                    const Spacer(),
                    Text(service['name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (service['price_range'] != null)
                      Text(service['price_range'],
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentsSection(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Departments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _departments.length,
            itemBuilder: (context, index) {
              final dept = _departments[index];
              final color = _getDeptColor(index);
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getDeptIcon(dept['name']), color: color),
                    const Spacer(),
                    Text(dept['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${dept['specialists_count'] ?? 0} Specialists',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInsuranceSection(AppLocalizations l10n, bool isDark) {
    List<String> payments = [];
    List<String> insurance = [];
    if (_hospital!['payment_methods'] != null) {
      payments = (_hospital!['payment_methods'] as List)
          .map((e) => e.toString().trim())
          .toList();
    }
    if (_hospital!['insurance_accepted'] != null) {
      insurance = (_hospital!['insurance_accepted'] as List)
          .map((e) => e.toString().trim())
          .toList();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (payments.isNotEmpty) ...[
            const Text('Payment Methods',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: payments
                  .map((p) => Chip(
                        avatar: Icon(_getPaymentIcon(p), size: 16),
                        label: Text(p, style: const TextStyle(fontSize: 11)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (insurance.isNotEmpty) ...[
            const Text('Insurance Accepted',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: insurance
                  .map((i) => Chip(
                        avatar: const Icon(Icons.health_and_safety,
                            size: 16, color: Colors.green),
                        label: Text(i, style: const TextStyle(fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactSection(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildContactRow(Icons.location_on,
              '${_hospital!['address'] ?? ''}, ${_hospital!['city'] ?? ''}'),
          if (_hospital!['phone'] != null)
            _buildContactRow(Icons.phone, _hospital!['phone'],
                onTap: () => _makeCall(_hospital!['phone'])),
          if (_hospital!['emergency_phone'] != null)
            _buildContactRow(Icons.emergency, _hospital!['emergency_phone'],
                onTap: () => _makeCall(_hospital!['emergency_phone']),
                color: Colors.red),
          if (_hospital!['email'] != null)
            _buildContactRow(Icons.email, _hospital!['email']),
          if (_hospital!['established_year'] != null)
            _buildContactRow(
                Icons.calendar_today, 'Est. ${_hospital!['established_year']}'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text,
      {VoidCallback? onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 13,
                        color: onTap != null ? AppColors.primary : null))),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Metrics',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._metrics.map((m) =>
              _buildMetricBar(m['name'] ?? '', (m['score'] ?? 0).toInt())),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, int score) {
    final color =
        score >= 80 ? Colors.green : (score >= 60 ? Colors.orange : Colors.red);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 13))),
              Text('$score%',
                  style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.2),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.reviews,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: _showWriteReview,
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text('Write Review'),
            ),
          ],
        ),
        if (_reviews.isNotEmpty)
          ..._reviews
              .take(3)
              .map((r) => ReviewCard(review: r, onHelpful: () {}))
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text('No reviews yet'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showWriteReview,
                  child: const Text('Be the first to review'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _openAICall,
                icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
                tooltip: 'AI Assistant',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _makeCall(_hospital!['phone']),
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/bookings'),
                icon: const Icon(Icons.calendar_month),
                label: Text(l10n.bookNow),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAICall() {
    final hospitalInfo = '''Hospital: ${_hospital!['name']}
Type: ${_hospital!['type']}
Location: ${_hospital!['address']}, ${_hospital!['city']}
AI Trust Score: ${_hospital!['ai_trust_score'] ?? 'N/A'}
Rating: ${_hospital!['rating'] ?? 'N/A'}
Total Beds: ${_hospital!['total_beds'] ?? 'N/A'}
Departments: ${_departments.map((d) => d['name']).join(', ')}''';

    showLiveAICallBottomSheet(
      context: context,
      config: LiveAICallConfig(
        specialist: 'physician',
        patientContext:
            'User is viewing hospital details. Please explain about this hospital and help them make a decision.\\n\\n$hospitalInfo',
      ),
    );
  }

  void _showWriteReview() async {
    final result = await showReviewSheet(
      context,
      hospitalId: widget.hospitalId,
      hospitalName: _hospital!['name'] ?? 'Hospital',
    );
    if (result == true) _loadData();
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

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  IconData _getServiceIcon(String? category) {
    switch (category) {
      case 'diagnostic':
        return Icons.biotech;
      case 'treatment':
        return Icons.medical_services;
      case 'surgery':
        return Icons.healing;
      case 'emergency':
        return Icons.emergency;
      case 'lab':
        return Icons.science;
      case 'imaging':
        return Icons.image_search;
      case 'pharmacy':
        return Icons.medication;
      default:
        return Icons.local_hospital;
    }
  }

  IconData _getDeptIcon(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('cardio')) return Icons.favorite;
    if (n.contains('neuro')) return Icons.psychology;
    if (n.contains('ortho')) return Icons.accessibility_new;
    if (n.contains('pediatr')) return Icons.child_care;
    if (n.contains('oncol')) return Icons.healing;
    if (n.contains('nephro')) return Icons.water_drop;
    return Icons.local_hospital;
  }

  Color _getDeptColor(int index) {
    final colors = [
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.pink
    ];
    return colors[index % colors.length];
  }

  IconData _getPaymentIcon(String method) {
    final m = method.toLowerCase();
    if (m.contains('cash')) return Icons.money;
    if (m.contains('card')) return Icons.credit_card;
    if (m.contains('esewa') || m.contains('khalti')) return Icons.phone_android;
    return Icons.payment;
  }
}
