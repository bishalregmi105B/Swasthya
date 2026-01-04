import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/medicine_alarm_service.dart';

/// Time slot with label and time
class TimeSlot {
  String label;
  TimeOfDay time;
  IconData icon;
  Color color;

  TimeSlot({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class AddReminderScreen extends StatefulWidget {
  final int? editReminderId;

  const AddReminderScreen({super.key, this.editReminderId});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();

  String _selectedForm = 'pill';
  String _selectedUnit = 'mg';
  String _selectedFrequency = 'daily';
  List<TimeSlot> _timeSlots = [
    TimeSlot(
      label: 'Morning Dose',
      time: const TimeOfDay(hour: 8, minute: 0),
      icon: Icons.wb_sunny,
      color: Colors.orange,
    ),
  ];
  bool _refillReminder = true;
  bool _criticalAlert = false;
  bool _isLoading = false;
  bool _isLoadingEdit = false;
  String? _aiSuggestion;

  bool get _isEditMode => widget.editReminderId != null;

  final List<Map<String, dynamic>> _formOptions = [
    {'value': 'pill', 'label': 'Pill', 'icon': Icons.circle},
    {'value': 'tablet', 'label': 'Tablet', 'icon': Icons.crop_square},
    {'value': 'injection', 'label': 'Injection', 'icon': Icons.vaccines},
    {'value': 'liquid', 'label': 'Liquid', 'icon': Icons.water_drop},
    {'value': 'capsule', 'label': 'Capsule', 'icon': Icons.medication},
    {'value': 'drops', 'label': 'Drops', 'icon': Icons.opacity},
  ];

  final List<String> _unitOptions = [
    'mg',
    'ml',
    'g',
    'mcg',
    'IU',
    'tablets',
    'drops'
  ];

  final List<Map<String, dynamic>> _frequencyOptions = [
    {'value': 'daily', 'label': 'Every Day'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'alternate', 'label': 'Alternate Days'},
    {'value': 'as_needed', 'label': 'As Needed'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingReminder();
    }
  }

  Future<void> _loadExistingReminder() async {
    setState(() => _isLoadingEdit = true);
    try {
      final data = await apiService.getReminderById(widget.editReminderId!);

      _nameController.text = data['medicine_name'] ?? '';
      _strengthController.text = data['strength']?.toString() ?? '';
      _selectedForm = data['form'] ?? 'pill';
      _selectedUnit = data['unit'] ?? 'mg';
      _selectedFrequency = data['frequency'] ?? 'daily';
      _refillReminder = data['refill_reminder'] ?? true;
      _criticalAlert = data['critical_alert'] ?? false;

      // Parse reminder times
      final times = data['reminder_times'] as List<dynamic>? ?? [];
      if (times.isNotEmpty) {
        _timeSlots = times.asMap().entries.map((entry) {
          final idx = entry.key;
          final t = entry.value.toString();
          final parts = t.split(':');
          final hour = int.tryParse(parts[0]) ?? 8;
          final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

          return TimeSlot(
            label: _getLabelForIndex(idx),
            time: TimeOfDay(hour: hour, minute: minute),
            icon: _getIconForIndex(idx),
            color: _getColorForIndex(idx),
          );
        }).toList();
      }

      setState(() => _isLoadingEdit = false);
    } catch (e) {
      setState(() => _isLoadingEdit = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reminder: $e')),
        );
      }
    }
  }

  String _getLabelForIndex(int idx) {
    const labels = [
      'Morning Dose',
      'Afternoon Dose',
      'Evening Dose',
      'Night Dose'
    ];
    return idx < labels.length ? labels[idx] : 'Dose ${idx + 1}';
  }

  IconData _getIconForIndex(int idx) {
    const icons = [
      Icons.wb_sunny,
      Icons.wb_cloudy,
      Icons.nights_stay,
      Icons.bedtime
    ];
    return idx < icons.length ? icons[idx] : Icons.schedule;
  }

  Color _getColorForIndex(int idx) {
    const colors = [Colors.orange, Colors.blue, Colors.indigo, Colors.purple];
    return idx < colors.length ? colors[idx] : Colors.grey;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _addTimeSlot() {
    final nextIdx = _timeSlots.length;
    setState(() {
      _timeSlots.add(TimeSlot(
        label: _getLabelForIndex(nextIdx),
        time: TimeOfDay(hour: 8 + (nextIdx * 6) % 24, minute: 0),
        icon: _getIconForIndex(nextIdx),
        color: _getColorForIndex(nextIdx),
      ));
    });
  }

  void _removeTimeSlot(int idx) {
    if (_timeSlots.length > 1) {
      setState(() => _timeSlots.removeAt(idx));
    }
  }

  Future<void> _pickTime(int idx) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _timeSlots[idx].time,
    );
    if (time != null) {
      setState(() => _timeSlots[idx].time = time);
    }
  }

  void _showFrequencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Frequency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._frequencyOptions.map((opt) => ListTile(
                  leading: Radio<String>(
                    value: opt['value'],
                    groupValue: _selectedFrequency,
                    onChanged: (v) {
                      setState(() => _selectedFrequency = v!);
                      Navigator.pop(ctx);
                    },
                  ),
                  title: Text(opt['label']),
                  onTap: () {
                    setState(() => _selectedFrequency = opt['value']);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReminder() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter medicine name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reminderData = {
        'medicine_name': _nameController.text,
        'strength':
            _strengthController.text.isEmpty ? null : _strengthController.text,
        'unit': _selectedUnit,
        'frequency': _selectedFrequency,
        'times_per_day': _timeSlots.length,
        'reminder_times': _timeSlots.map((t) => _timeToString(t.time)).toList(),
        'form': _selectedForm,
        'refill_reminder': _refillReminder,
        'critical_alert': _criticalAlert,
      };

      if (_isEditMode) {
        await apiService.updateReminder(widget.editReminderId!, reminderData);
        await medicineAlarmService.cancelReminder(widget.editReminderId!);
        await medicineAlarmService.scheduleMultipleReminders(
          baseReminderId: widget.editReminderId!,
          medicineName: _nameController.text,
          dosage: '${_strengthController.text} $_selectedUnit',
          times: _timeSlots.map((t) => _timeToString(t.time)).toList(),
        );
      } else {
        final result = await apiService.createReminder(reminderData);
        if (result['reminder'] != null) {
          final reminderId = result['reminder']['id'] as int;
          await medicineAlarmService.scheduleMultipleReminders(
            baseReminderId: reminderId,
            medicineName: _nameController.text,
            dosage: '${_strengthController.text} $_selectedUnit',
            times: _timeSlots.map((t) => _timeToString(t.time)).toList(),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEditMode ? 'Reminder updated!' : 'Reminder saved!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditMode ? 'Edit Reminder' : 'Add Reminder'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveReminder,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine Name Input
                _buildSectionLabel('Medicine Name'),
                const SizedBox(height: 8),
                _buildMedicineInput(),
                const SizedBox(height: 24),

                // Form Selection
                _buildSectionLabel('Form'),
                const SizedBox(height: 12),
                _buildFormChips(),
                const SizedBox(height: 24),

                // Dosage Section
                _buildSectionTitle('Dosage'),
                const SizedBox(height: 12),
                _buildDosageRow(),
                const SizedBox(height: 24),

                // AI Insight Card
                if (_aiSuggestion != null) ...[
                  _buildAIInsightCard(),
                  const SizedBox(height: 24),
                ],

                // Schedule Section
                _buildScheduleSection(),
                const SizedBox(height: 24),

                // Settings Section
                _buildSettingsSection(),
              ],
            ),
          ),
          // Sticky Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyFooter(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMedicineInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C232E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3441) : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: 'Search medicine (e.g., Atorvastatin)...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildFormChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _formOptions.map((opt) {
          final isSelected = _selectedForm == opt['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedForm = opt['value']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade400,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      opt['icon'],
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      opt['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDosageRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Strength
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Strength',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C232E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A3441)
                          : Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _strengthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '20',
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Unit
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unit',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showUnitPicker(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C232E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A3441)
                            : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedUnit),
                      Icon(Icons.expand_more,
                          color: Colors.grey.shade500, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Unit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _unitOptions
                  .map((unit) => ChoiceChip(
                        label: Text(unit),
                        selected: _selectedUnit == unit,
                        onSelected: (_) {
                          setState(() => _selectedUnit = unit);
                          Navigator.pop(ctx);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Insight',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  _aiSuggestion ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: Colors.white.withOpacity(0.5),
                  ),
                  child: Text('Apply Suggestion',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final frequencyLabel = _frequencyOptions
        .firstWhere((o) => o['value'] == _selectedFrequency)['label'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: _showFrequencyPicker,
              child: Text('Edit', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C232E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? const Color(0xFF2A3441) : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // Frequency Row
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month,
                      color: Colors.purple, size: 20),
                ),
                title: const Text('Frequency',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(frequencyLabel,
                        style: TextStyle(color: Colors.grey.shade500)),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
                onTap: _showFrequencyPicker,
              ),
              // Time Slots
              ..._timeSlots.asMap().entries.map((entry) {
                final idx = entry.key;
                final slot = entry.value;
                return Column(
                  children: [
                    Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF2A3441)
                            : Colors.grey.shade200),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: slot.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(slot.icon, color: slot.color, size: 20),
                      ),
                      title: Text(slot.label,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF101822)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2A3441)
                                      : Colors.grey.shade300),
                            ),
                            child: Text(
                              _formatTime(slot.time),
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 14),
                            ),
                          ),
                          if (_timeSlots.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _removeTimeSlot(idx),
                              color: Colors.red.shade400,
                            ),
                        ],
                      ),
                      onTap: () => _pickTime(idx),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Add Time Button
        GestureDetector(
          onTap: _addTimeSlot,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade400,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_alarm, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add another time',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // Refill Reminder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C232E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? const Color(0xFF2A3441) : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Refill Reminder',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('Alert when supply is low',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              Switch(
                value: _refillReminder,
                onChanged: (v) => setState(() => _refillReminder = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Critical Alerts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C232E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? const Color(0xFF2A3441) : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Critical Alerts',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('Play sound even in silent mode',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              Switch(
                value: _criticalAlert,
                onChanged: (v) => setState(() => _criticalAlert = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8),
        border: Border(
            top: BorderSide(
                color:
                    isDark ? const Color(0xFF2A3441) : Colors.grey.shade300)),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                _isEditMode ? 'Update Reminder' : 'Save Reminder',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
              ),
      ),
    );
  }
}
