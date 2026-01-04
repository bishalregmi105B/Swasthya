import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/medicine_alarm_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';

/// Screen to view and manage a single medicine reminder
class ReminderDetailScreen extends StatefulWidget {
  final int reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  Map<String, dynamic>? _reminder;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    try {
      final data = await apiService.getReminderById(widget.reminderId);
      setState(() {
        _reminder = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteReminder),
        content: const Text(
            'Are you sure you want to delete this reminder? This will also cancel all scheduled alarms.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      // Cancel alarms first
      await medicineAlarmService.cancelReminder(widget.reminderId);

      // Delete from API
      await apiService.deleteReminder(widget.reminderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reminder deleted'), backgroundColor: Colors.green),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleActive() async {
    if (_reminder == null) return;

    final newActive = !(_reminder!['is_active'] as bool? ?? true);
    try {
      await apiService
          .updateReminder(widget.reminderId, {'is_active': newActive});

      if (newActive) {
        // Re-schedule alarms
        final times = _reminder!['reminder_times'] as List<dynamic>? ?? [];
        await medicineAlarmService.scheduleMultipleReminders(
          baseReminderId: widget.reminderId,
          medicineName: _reminder!['medicine_name'] ?? 'Medicine',
          dosage: _reminder!['strength'] ?? '1 dose',
          times: List<String>.from(times),
        );
      } else {
        // Cancel alarms
        await medicineAlarmService.cancelReminder(widget.reminderId);
      }

      setState(() {
        _reminder!['is_active'] = newActive;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(newActive ? 'Reminder activated' : 'Reminder paused')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _openAIGuidance() {
    if (_reminder == null) return;

    showLiveAICallBottomSheet(
      context: context,
      config: LiveAICallConfig(
        specialist: 'Pharmacist',
        patientContext: '''Medicine: ${_reminder!['medicine_name']}
Dosage: ${_reminder!['strength'] ?? 'Not specified'}
Form: ${_reminder!['form'] ?? 'Not specified'}  
Instructions: ${_reminder!['instructions'] ?? 'No special instructions'}

The user wants guidance on how to take this medicine properly, side effects to watch for, and any food or drug interactions.''',
        systemPrompt:
            '''You are a helpful pharmacist assistant. Provide clear, helpful guidance about the medicine. Include:
- How to take this medicine properly
- Any common side effects to watch for
- Food or drug interactions to avoid
- Tips for remembering to take it''',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_reminder?['medicine_name'] ?? 'Reminder'),
        actions: [
          if (!_isLoading && _reminder != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await context
                    .push('/reminders/add?edit=${widget.reminderId}');
                if (result == true) _loadReminder();
              },
            ),
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteReminder,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminder == null
              ? const Center(child: Text('Reminder not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine card
                      _buildMedicineCard(),
                      const SizedBox(height: 16),

                      // Schedule times
                      _buildScheduleCard(),
                      const SizedBox(height: 16),

                      // AI Guidance button
                      _buildAIGuidanceCard(),
                      const SizedBox(height: 16),

                      // Quick actions
                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      // Status toggle
                      _buildStatusToggle(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMedicineCard() {
    final isActive = _reminder!['is_active'] as bool? ?? true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.medication,
                    size: 40,
                    color: isActive ? AppColors.primary : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reminder!['medicine_name'] ?? 'Unknown',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_reminder!['strength'] ?? ''} ${_reminder!['form'] ?? ''}'
                            .trim(),
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                      if (!isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Paused',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_reminder!['instructions'] != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _reminder!['instructions'],
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    final times = _reminder!['reminder_times'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Schedule',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: times.map((t) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alarm,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        t.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Frequency: ${_reminder!['frequency'] ?? 'Daily'}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIGuidanceCard() {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: _openAIGuidance,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.psychology, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Medicine Guide',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get personalized guidance about taking this medicine',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await apiService.markReminderTaken(widget.reminderId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Marked as taken! ✅'),
                    backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark Taken'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: Colors.green,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              medicineAlarmService.snoozeReminder(widget.reminderId,
                  minutes: 30);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Snoozed for 30 minutes')),
              );
            },
            icon: const Icon(Icons.snooze),
            label: const Text('Snooze 30m'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    final isActive = _reminder!['is_active'] as bool? ?? true;

    return Card(
      child: SwitchListTile(
        title: Text(AppLocalizations.of(context)!.reminderActive),
        subtitle: Text(isActive
            ? 'Alarms will ring at scheduled times'
            : 'Alarms are paused'),
        value: isActive,
        onChanged: (_) => _toggleActive(),
        secondary: Icon(
          isActive ? Icons.notifications_active : Icons.notifications_off,
          color: isActive ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }
}
