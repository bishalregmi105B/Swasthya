import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/medicine_alarm_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<dynamic> _reminders = [];
  bool _isLoading = true;
  bool _isOffline = false;
  Map<String, List<dynamic>> _groupedReminders = {};

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _checkAlarmPermissions();
  }

  Future<void> _checkAlarmPermissions() async {
    // Request battery optimization exemption first
    await medicineAlarmService.requestBatteryOptimizationExemption();

    // Check and show warning if needed
    final diagnostics = await medicineAlarmService.runDiagnostics();
    if ((!diagnostics['exactAlarmsAllowed'] ||
            diagnostics['pendingCount'] == 0) &&
        mounted) {
      _showAlarmSetupDialog();
    }
  }

  void _showAlarmSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
                child: Text('Enable Alarms', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medicine alarms need special permissions to work on this device.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Required settings:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Autostart → ON'),
            const Text('2. Battery saver → No restrictions'),
            const Text('3. Show on lock screen → ON'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                const channel = MethodChannel('com.example.swasthya/settings');
                try {
                  await channel.invokeMethod('openAutoStartSettings');
                } catch (e) {
                  await channel.invokeMethod('openAppSettings');
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I\'ve enabled it'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);

    try {
      // Try to fetch from API
      final data = await apiService.getReminders();
      final reminders = data['reminders'] ?? [];

      _groupReminders(reminders);
      setState(() {
        _reminders = reminders;
        _isLoading = false;
        _isOffline = false;
      });

      // Cache and sync alarms in background (don't block UI or trigger offline)
      try {
        await OfflineCacheService.cacheReminders(
            List<Map<String, dynamic>>.from(
                reminders.map((r) => Map<String, dynamic>.from(r))));
        await _syncAlarmsWithReminders(reminders);
      } catch (cacheError) {
        debugPrint('[Reminders] Cache/Alarm error: $cacheError');
      }
    } catch (e) {
      debugPrint('[Reminders] API error: $e');
      // Fallback to cached data when offline
      final cachedReminders = OfflineCacheService.getCachedReminders();
      if (cachedReminders != null && cachedReminders.isNotEmpty) {
        _groupReminders(cachedReminders);
        setState(() {
          _reminders = cachedReminders;
          _isLoading = false;
          _isOffline = true;
        });
      } else {
        setState(() {
          _reminders = [];
          _isLoading = false;
          _isOffline = true;
        });
      }
    }
  }

  /// Sync local alarms with fetched reminders
  Future<void> _syncAlarmsWithReminders(List<dynamic> reminders) async {
    for (var reminder in reminders) {
      final id = reminder['id'] as int?;
      final name = reminder['medicine_name'] as String? ?? 'Medicine';
      final times = reminder['reminder_times'] as List<dynamic>? ?? [];
      final strength = reminder['strength'] as String? ?? '1 dose';
      final isActive = reminder['is_active'] as bool? ?? true;

      if (id != null && isActive && times.isNotEmpty) {
        await medicineAlarmService.scheduleMultipleReminders(
          baseReminderId: id,
          medicineName: name,
          dosage: strength,
          times: List<String>.from(times),
        );
      }
    }
  }

  void _groupReminders(List<dynamic> reminders) {
    _groupedReminders = {'morning': [], 'afternoon': [], 'evening': []};
    for (var r in reminders) {
      final times = r['reminder_times'] as List<dynamic>? ?? [];
      for (var t in times) {
        final hour = int.tryParse(t.toString().split(':').first) ?? 0;
        if (hour < 12) {
          _groupedReminders['morning']!.add({...r, 'time': t});
        } else if (hour < 17) {
          _groupedReminders['afternoon']!.add({...r, 'time': t});
        } else {
          _groupedReminders['evening']!.add({...r, 'time': t});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myMedicines),
        actions: [
          // Test immediate notification
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Immediate',
            onPressed: () async {
              await medicineAlarmService.showTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Immediate notification sent!')),
              );
            },
          ),
          // Test scheduled notification (10 seconds)
          IconButton(
            icon: const Icon(Icons.alarm),
            tooltip: 'Test Scheduled (10s)',
            onPressed: () async {
              final success = await medicineAlarmService.scheduleTestReminder();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Alarm scheduled for 10 seconds! Wait for notification...'
                        : 'Permission required! Please enable "Alarms & reminders" in settings.'),
                    backgroundColor: success ? Colors.green : Colors.orange,
                    duration: Duration(seconds: success ? 3 : 5),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/reminders/add'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReminders,
              child: Column(
                children: [
                  // Offline indicator
                  if (_isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.orange.shade100,
                      child: const Row(
                        children: [
                          Icon(Icons.cloud_off, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Offline mode - showing cached data',
                              style:
                                  TextStyle(color: Colors.orange, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildAIInsight(context, l10n),
                  Expanded(
                    child: _reminders.isEmpty
                        ? _buildEmptyState(context, l10n)
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (_groupedReminders['morning']!.isNotEmpty)
                                _buildTimeSection(
                                    context,
                                    l10n.morning,
                                    '06:00 - 12:00',
                                    Colors.orange,
                                    _groupedReminders['morning']!),
                              if (_groupedReminders['afternoon']!.isNotEmpty)
                                _buildTimeSection(
                                    context,
                                    l10n.afternoon,
                                    '12:00 - 17:00',
                                    AppColors.primary,
                                    _groupedReminders['afternoon']!),
                              if (_groupedReminders['evening']!.isNotEmpty)
                                _buildTimeSection(
                                    context,
                                    l10n.evening,
                                    '17:00 - 22:00',
                                    Colors.indigo,
                                    _groupedReminders['evening']!),
                            ],
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/reminders/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAIInsight(BuildContext context, AppLocalizations l10n) {
    final totalReminders = _reminders.length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            Colors.blue.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.aiInsight,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(
                  totalReminders > 0
                      ? "You have $totalReminders active medicine reminders. Stay consistent!"
                      : "Add your medicines to get personalized reminders.",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No reminders yet',
              style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.5))),
          const SizedBox(height: 8),
          Text('Add your medicines to never miss a dose',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.4))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/reminders/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(BuildContext context, String title, String timeRange,
      Color color, List<dynamic> reminders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(timeRange,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        ...reminders.map((r) => _buildReminderCard(context, r, color)),
      ],
    );
  }

  Widget _buildReminderCard(
      BuildContext context, dynamic reminder, Color color) {
    final isCritical = reminder['critical_alert'] ?? false;
    final reminderId = reminder['id'] as int?;

    return GestureDetector(
      onTap: reminderId != null
          ? () async {
              final result = await context.push('/reminders/$reminderId');
              if (result == true) _loadReminders();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: isCritical
              ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5)
              : Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getFormIcon(reminder['form']), color: color, size: 22),
                  Text(reminder['time'] ?? '',
                      style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder['medicine_name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      if (isCritical)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('Critical',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reminder['strength'] ?? ''} ${reminder['unit'] ?? ''} • ${reminder['instructions'] ?? ''}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.check_circle_outline, color: color),
              onPressed: () async {
                try {
                  await apiService.markReminderTaken(reminder['id']);
                  _loadReminders();
                } catch (e) {}
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFormIcon(String? form) {
    switch (form) {
      case 'pill':
        return Icons.circle;
      case 'tablet':
        return Icons.crop_din;
      case 'injection':
        return Icons.vaccines;
      case 'liquid':
        return Icons.water_drop;
      case 'cream':
        return Icons.spa;
      case 'drops':
        return Icons.opacity;
      default:
        return Icons.medication;
    }
  }
}
