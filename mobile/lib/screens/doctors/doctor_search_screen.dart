import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _doctors = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _filterChips = [
    {'label': 'All', 'icon': Icons.check, 'color': null},
    {'label': 'Video Call', 'icon': Icons.videocam, 'color': Colors.green},
    {'label': 'Cardiologist', 'icon': Icons.favorite, 'color': Colors.red},
    {'label': 'Available Today', 'icon': Icons.schedule, 'color': Colors.blue},
    {'label': 'Top Rated', 'icon': Icons.star, 'color': Colors.amber},
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getDoctors();
      final doctors = response['doctors'] ?? [];

      // Cache the data for offline use
      await OfflineCacheService.cacheDoctors(List<Map<String, dynamic>>.from(
          doctors.map((e) => Map<String, dynamic>.from(e))));

      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache
      final cachedDoctors = OfflineCacheService.getCachedDoctors();
      if (cachedDoctors != null && cachedDoctors.isNotEmpty) {
        setState(() {
          _doctors = cachedDoctors;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              decoration: BoxDecoration(
                color:
                    (isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8))
                        .withOpacity(0.95),
                border: Border(
                  bottom: BorderSide(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                        const Text(
                          'Find a Specialist',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.notifications_outlined),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF101822)
                                          : Colors.white,
                                      width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // AI Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF282F39) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                        border: Border.all(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.smart_toy,
                              color: Colors.grey.shade400, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Describe symptoms or find doctor...',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.tune,
                                size: 18,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filterChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final chip = _filterChips[index];
                        final isSelected = _selectedFilter == chip['label'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = chip['label']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF136DEC)
                                  : (isDark
                                      ? const Color(0xFF282F39)
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF136DEC)
                                    : (isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  chip['icon'],
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : (chip['color'] ??
                                          (isDark
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade700)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  chip['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Doctor List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadDoctors,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _doctors.length + 1, // +1 for header
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Section Header
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'TOP MATCHES FOR "${_searchQuery.toUpperCase()}"'
                                        : 'AVAILABLE SPECIALISTS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF136DEC),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }

                          final doctor = _doctors[index - 1];
                          return _buildDoctorCard(
                              context, doctor, isDark, index - 1);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),

      // Floating AI Button
      floatingActionButton: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF136DEC).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF136DEC),
          elevation: 0,
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(
      BuildContext context, dynamic doctor, bool isDark, int index) {
    // Generate some display values
    final name = doctor['name'] ?? 'Dr. Unknown';
    final specialization =
        _capitalizeSpec(doctor['specialization'] ?? 'General');
    final experience = doctor['experience_years'] ?? 5;
    final rating = (doctor['rating'] ?? 4.5).toDouble();
    final languages = (doctor['languages'] as List?)?.join(', ') ?? 'English';
    final videoFee = doctor['video_fee'] ?? 45;
    final isAvailableToday =
        index % 3 == 0; // Demo: every 3rd doctor available today
    final aiMatch = 98 - (index * 5); // Demo: decreasing AI match
    final hasVideo = doctor['video_fee'] != null;
    final hasChat = doctor['chat_fee'] != null;
    final profileImage = doctor['profile_image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2027) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // AI Match Badge (top right, rotated)
          if (index < 3 && aiMatch > 80)
            Positioned(
              top: -20,
              right: -12,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF136DEC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF101822) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$aiMatch% AI Match',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          Column(
            children: [
              // Doctor Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Photo with Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF136DEC).withOpacity(0.1),
                          image: profileImage != null
                              ? DecorationImage(
                                  image: NetworkImage(profileImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profileImage == null
                            ? const Icon(Icons.person,
                                size: 36, color: Color(0xFF136DEC))
                            : null,
                      ),
                      // Video/Chat Badge
                      if (hasVideo || hasChat)
                        Positioned(
                          bottom: -6,
                          right: -6,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: hasVideo ? Colors.green : Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1C2027)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              hasVideo ? Icons.videocam : Icons.chat,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Doctor Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$specialization • $experience yrs exp.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Rating Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 12, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Languages Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.translate,
                                  size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                languages,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
              ),

              // Bottom Row: Availability + Price + Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Next Available
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT AVAILABLE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAvailableToday
                            ? 'Today, 2:30 PM'
                            : 'Tomorrow, 9:00 AM',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isAvailableToday
                              ? Colors.green
                              : (isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),

                  // Price + Button
                  Row(
                    children: [
                      Text(
                        'Rs. $videoFee',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/doctors/${doctor['id']}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: hasVideo && isAvailableToday
                                ? const Color(0xFF136DEC)
                                : (isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasVideo && isAvailableToday
                                ? 'Book Video'
                                : 'Profile',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: hasVideo && isAvailableToday
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white
                                      : Colors.grey.shade900),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalizeSpec(String spec) {
    if (spec.isEmpty) return spec;
    return spec[0].toUpperCase() + spec.substring(1);
  }
}
