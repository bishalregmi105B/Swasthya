import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  List<dynamic> _upcomingAppointments = [];
  List<dynamic> _pastAppointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAppointments();
      final appointments = response['appointments'] as List<dynamic>? ?? [];

      // Cache the data for offline use
      await OfflineCacheService.cacheAppointments(
          List<Map<String, dynamic>>.from(
              appointments.map((e) => Map<String, dynamic>.from(e))));

      _processAppointments(appointments);
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      // Try loading from cache
      final cachedAppointments = OfflineCacheService.getCachedAppointments();
      if (cachedAppointments != null && cachedAppointments.isNotEmpty) {
        _processAppointments(cachedAppointments);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _processAppointments(List<dynamic> appointments) {
    final now = DateTime.now();
    setState(() {
      _upcomingAppointments = appointments.where((a) {
        final dateStr = a['appointment_date'];
        if (dateStr == null) return true;
        try {
          final date = DateTime.parse(dateStr);
          return date.isAfter(now.subtract(const Duration(days: 1)));
        } catch (_) {
          return true;
        }
      }).toList();

      _pastAppointments = appointments.where((a) {
        final dateStr = a['appointment_date'];
        if (dateStr == null) return false;
        try {
          final date = DateTime.parse(dateStr);
          return date.isBefore(now.subtract(const Duration(days: 1)));
        } catch (_) {
          return false;
        }
      }).toList();

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: Text(l10n.myAppointments),
        backgroundColor:
            isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF136DEC),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF136DEC),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Upcoming'),
                  if (_upcomingAppointments.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF136DEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_upcomingAppointments.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(_upcomingAppointments,
                    isUpcoming: true, isDark: isDark),
                _buildAppointmentsList(_pastAppointments,
                    isUpcoming: false, isDark: isDark),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/doctors'),
        backgroundColor: const Color(0xFF136DEC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book New', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAppointmentsList(List<dynamic> appointments,
      {required bool isUpcoming, required bool isDark}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today : Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming appointments' : 'No past appointments',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push('/doctors'),
                child: const Text('Book an appointment'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment, isUpcoming, isDark);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(
      dynamic appointment, bool isUpcoming, bool isDark) {
    final doctorName = appointment['doctor_name'] ??
        appointment['doctor']?['name'] ??
        'Doctor';
    final specialization = appointment['specialization'] ??
        appointment['doctor']?['specialization'] ??
        'Specialist';
    final dateStr = appointment['appointment_date'];
    final timeStr = appointment['appointment_time'];
    final status = appointment['status'] ?? 'scheduled';
    final consultationType = appointment['type'] ?? 'video';
    final appointmentId = appointment['id'];

    DateTime? scheduledDateTime;
    String formattedDate = 'Date TBD';
    String formattedTime = timeStr ?? '';

    if (dateStr != null) {
      try {
        scheduledDateTime = DateTime.parse(dateStr);

        // Combine date with time if time is provided
        if (timeStr != null && timeStr.isNotEmpty) {
          try {
            // Parse time in format like "10:30 AM" or "14:30"
            final timeParts =
                timeStr.replaceAll(' AM', '').replaceAll(' PM', '').split(':');
            int hour = int.parse(timeParts[0]);
            int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

            // Handle AM/PM
            if (timeStr.contains('PM') && hour != 12) hour += 12;
            if (timeStr.contains('AM') && hour == 12) hour = 0;

            scheduledDateTime = DateTime(
              scheduledDateTime.year,
              scheduledDateTime.month,
              scheduledDateTime.day,
              hour,
              minute,
            );
          } catch (_) {}
        }

        formattedDate = DateFormat('EEE, MMM d, y').format(scheduledDateTime!);
      } catch (_) {}
    }

    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    // Enable join button when appointment time is reached (and up to 1 hour after)
    final now = DateTime.now();
    final bool canJoin = isUpcoming &&
        status != 'cancelled' &&
        scheduledDateTime != null &&
        now.isAfter(scheduledDateTime.subtract(const Duration(minutes: 5))) &&
        now.isBefore(scheduledDateTime.add(const Duration(hours: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Doctor Info Row
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF136DEC).withOpacity(0.1),
                ),
                child: const Icon(Icons.person,
                    size: 28, color: Color(0xFF136DEC)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      specialization,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date & Time Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(formattedDate,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const Spacer(),
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(formattedTime,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const Spacer(),
                Icon(
                  consultationType == 'video' ? Icons.videocam : Icons.chat,
                  size: 18,
                  color: const Color(0xFF136DEC),
                ),
                const SizedBox(width: 4),
                Text(
                  consultationType == 'video' ? 'Video' : 'Chat',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF136DEC)),
                ),
              ],
            ),
          ),

          // Action Buttons
          if (isUpcoming && status != 'cancelled') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelAppointment(appointmentId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: canJoin
                        ? () => _joinCall(appointmentId, consultationType,
                            doctorName: doctorName)
                        : null,
                    icon: Icon(consultationType == 'video'
                        ? Icons.videocam
                        : Icons.chat),
                    label: Text(canJoin ? 'Join Now' : 'Join (15 min before)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF136DEC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(int? appointmentId) async {
    if (appointmentId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelAppointment),
        content:
            const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.cancelAppointment(appointmentId);
        _loadAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Appointment cancelled'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to cancel: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _joinCall(int? appointmentId, String consultationType,
      {String? doctorName, String? doctorImage}) async {
    if (appointmentId == null) return;

    try {
      // Get video/room info from backend
      final tokenResponse = await _apiService.getVideoCallToken(appointmentId);
      final roomId = tokenResponse['room_id'] ??
          tokenResponse['room_name'] ??
          'room_$appointmentId';
      final domain = tokenResponse['domain'] ?? 'meet.jit.si';
      final doctor = tokenResponse['doctor'];

      // Navigate to video call screen
      if (mounted) {
        context.push('/video-call', extra: {
          'appointmentId': appointmentId,
          'roomId': roomId,
          'domain': domain,
          'consultationType': consultationType,
          'doctorName': doctorName ?? doctor?['name'] ?? 'Doctor',
          'doctorImage': doctorImage ?? doctor?['profile_image'],
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to join: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
