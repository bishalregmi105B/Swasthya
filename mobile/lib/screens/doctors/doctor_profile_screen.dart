import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  final int doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _doctor;
  bool _isLoading = true;
  String _selectedConsultationType = 'video';
  int _selectedDateIndex = 0;
  String? _selectedTime;
  bool _isFavorite = false;

  final List<Map<String, dynamic>> _dates = [];
  final List<String> _timeSlots = [
    '09:00',
    '10:30',
    '14:00',
    '16:00',
    '16:30',
    '17:00'
  ];
  final List<String> _bookedSlots = [
    '09:00',
    '10:30'
  ]; // Demo: some slots already booked

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadDoctor();
  }

  void _generateDates() {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      _dates.add({
        'day': [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun'
        ][date.weekday - 1],
        'date': date.day,
      });
    }
  }

  Future<void> _loadDoctor() async {
    setState(() => _isLoading = true);
    try {
      final doctor = await _apiService.getDoctor(widget.doctorId);

      // Cache for offline use
      await OfflineCacheService.cacheData('doctor_${widget.doctorId}', doctor);

      setState(() {
        _doctor = doctor;
        _isLoading = false;
      });
    } catch (e) {
      // Try loading from cache
      final cached =
          OfflineCacheService.getCachedData('doctor_${widget.doctorId}');
      if (cached != null) {
        setState(() {
          _doctor = cached;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _bookAppointment(BuildContext context) async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate scheduled datetime
    final now = DateTime.now();
    final selectedDate = now.add(Duration(days: _selectedDateIndex));
    final timeParts = _selectedTime!.split(':');
    final scheduledAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    try {
      // Format date and time separately as backend expects
      final dateStr =
          '${scheduledAt.year}-${scheduledAt.month.toString().padLeft(2, '0')}-${scheduledAt.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

      await _apiService.bookAppointment({
        'doctor_id': widget.doctorId,
        'appointment_date': dateStr,
        'appointment_time': timeStr,
        'type': _selectedConsultationType,
        'notes': 'Booked via mobile app',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/appointments');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final doctor = _doctor ?? {};
    final name = doctor['name'] ?? 'Dr. Unknown';
    final specialization =
        _capitalizeSpec(doctor['specialization'] ?? 'Specialist');
    final experience = doctor['experience_years'] ?? 12;
    final totalPatients = doctor['total_patients'] ?? 5000;
    final rating = (doctor['rating'] ?? 4.9).toDouble();
    final totalReviews = doctor['total_reviews'] ?? 320;
    final about = doctor['about'] ??
        'Experienced specialist with expertise in treating complex conditions.';
    final videoFee = doctor['video_fee'] ?? 45;
    final chatFee = doctor['chat_fee'] ?? 20;
    final profileImage = doctor['profile_image'];
    final isVerified = doctor['is_verified'] ?? true;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
      body: CustomScrollView(
        slivers: [
          // Sticky Header
          SliverAppBar(
            pinned: true,
            backgroundColor:
                (isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8))
                    .withOpacity(0.95),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
            title: const Text(
              'Doctor Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => _isFavorite = !_isFavorite),
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Image with Verified Badge
                      Stack(
                        children: [
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF136DEC).withOpacity(0.1),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.white,
                                  width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 16,
                                ),
                              ],
                              image: profileImage != null
                                  ? DecorationImage(
                                      image: NetworkImage(profileImage),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profileImage == null
                                ? const Icon(Icons.person,
                                    size: 56, color: Color(0xFF136DEC))
                                : null,
                          ),
                          if (isVerified)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF101822)
                                        : Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.verified,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Senior $specialization',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF136DEC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: const Text(
                          'AI-Verified Expert',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildStatItem('$experience Yrs', 'Experience'),
                        Container(
                            width: 1,
                            height: 40,
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200),
                        _buildStatItem(
                            '${_formatNumber(totalPatients)}+', 'Patients'),
                        Container(
                            width: 1,
                            height: 40,
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200),
                        _buildStatItem(rating.toStringAsFixed(1), 'Reviews',
                            showStar: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // AI Insight Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF312E81), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF312E81).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.blue.shade300, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'AI INSIGHT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade200,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Performance Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analysis of $totalReviews reviews indicates high proficiency in treatments. Patients consistently praise empathy and quick diagnosis turnaround.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade100.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Consultation Types
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consultation Type',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildConsultationType(
                              isDark,
                              'Video Call',
                              'Rs. $videoFee',
                              '30 mins session',
                              Icons.videocam,
                              _selectedConsultationType == 'video',
                              () => setState(
                                  () => _selectedConsultationType = 'video'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildConsultationType(
                              isDark,
                              'Chat',
                              'Rs. $chatFee',
                              '24hrs active',
                              Icons.chat_bubble,
                              _selectedConsultationType == 'chat',
                              () => setState(
                                  () => _selectedConsultationType = 'chat'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Availability Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Availability',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Next: Today, 4:00 PM',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF136DEC),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date Strip
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _dates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final date = _dates[index];
                          final isSelected = _selectedDateIndex == index;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDateIndex = index),
                            child: Container(
                              width: 64,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF136DEC)
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade200,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF136DEC)
                                              .withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    date['day'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${date['date']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white
                                              : Colors.grey.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Slots
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _timeSlots.map((time) {
                          final isBooked = _bookedSlots.contains(time);
                          final isSelected = _selectedTime == time;
                          return GestureDetector(
                            onTap: isBooked
                                ? null
                                : () => setState(() => _selectedTime = time),
                            child: Container(
                              width:
                                  (MediaQuery.of(context).size.width - 56) / 4,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF136DEC)
                                    : (isBooked
                                        ? (isDark
                                            ? Colors.grey.shade800
                                                .withOpacity(0.5)
                                            : Colors.grey.shade50)
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF136DEC)
                                      : (isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade200),
                                ),
                              ),
                              child: Text(
                                time,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isBooked
                                          ? Colors.grey.shade400
                                          : (isDark
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade600)),
                                  decoration: isBooked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // About Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About Doctor',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        about,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Read more',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF136DEC),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reviews Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reviews',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF136DEC),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            // Big Rating
                            SizedBox(
                              width: 80,
                              child: Column(
                                children: [
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.star,
                                          size: 14, color: Colors.amber),
                                      Icon(Icons.star,
                                          size: 14, color: Colors.amber),
                                      Icon(Icons.star,
                                          size: 14, color: Colors.amber),
                                      Icon(Icons.star,
                                          size: 14, color: Colors.amber),
                                      Icon(Icons.star_half,
                                          size: 14, color: Colors.amber),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalReviews reviews',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Rating Bars
                            Expanded(
                              child: Column(
                                children: [
                                  _buildRatingBar('5', 0.85, isDark),
                                  _buildRatingBar('4', 0.10, isDark),
                                  _buildRatingBar('3', 0.02, isDark),
                                  _buildRatingBar('2', 0.02, isDark),
                                  _buildRatingBar('1', 0.01, isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 120), // Space for bottom button
              ],
            ),
          ),
        ],
      ),

      // Fixed Bottom Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
          border: Border(
              top: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
        ),
        child: GestureDetector(
          onTap: () => _bookAppointment(context),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF136DEC),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF136DEC).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Book Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {bool showStar = false}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (showStar) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 16, color: Colors.amber),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationType(
    bool isDark,
    String title,
    String price,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF136DEC).withOpacity(0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF136DEC)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF136DEC).withOpacity(0.2)
                        : (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFF136DEC)
                        : Colors.grey.shade500,
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF136DEC)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected
                        ? const Color(0xFF136DEC)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF136DEC) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(String stars, double percentage, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              stars,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: percentage > 0.05
                        ? const Color(0xFF136DEC)
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeSpec(String spec) {
    if (spec.isEmpty) return spec;
    return spec[0].toUpperCase() + spec.substring(1);
  }

  String _formatNumber(int num) {
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(num % 1000 == 0 ? 0 : 1)}k';
    }
    return num.toString();
  }
}
