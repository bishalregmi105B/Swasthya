import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme.dart';
import '../../services/medicine_alarm_service.dart';

/// Full-screen alarm UI that appears when medicine reminder fires
/// Similar to a phone call incoming screen
class MedicineAlarmScreen extends StatefulWidget {
  final int reminderId;
  final String medicineName;
  final String dosage;
  final String? instructions;

  const MedicineAlarmScreen({
    super.key,
    required this.reminderId,
    required this.medicineName,
    required this.dosage,
    this.instructions,
  });

  @override
  State<MedicineAlarmScreen> createState() => _MedicineAlarmScreenState();
}

class _MedicineAlarmScreenState extends State<MedicineAlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _autoSnoozeTimer;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Play alarm sound
    _playAlarmSound();

    // Auto-snooze after 60 seconds if no action
    _autoSnoozeTimer = Timer(const Duration(seconds: 60), _snooze);
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(
        UrlSource(
            'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('[AlarmScreen] Audio error: $e');
    }
  }

  void _stopAlarm() {
    _audioPlayer.stop();
    _autoSnoozeTimer?.cancel();
  }

  void _takeMedicine() {
    _stopAlarm();
    // TODO: Mark medicine as taken in backend
    Navigator.of(context).pop('taken');
  }

  void _snooze() {
    _stopAlarm();
    medicineAlarmService.snoozeReminder(widget.reminderId, minutes: 10);
    Navigator.of(context).pop('snoozed');
  }

  void _dismiss() {
    _stopAlarm();
    Navigator.of(context).pop('dismissed');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    _autoSnoozeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Pulsing medicine icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.medication,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Time to take medicine
              const Text(
                '💊 Time to Take Medicine',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // Medicine name
              Text(
                widget.medicineName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Dosage
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.dosage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Instructions if any
              if (widget.instructions != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.instructions!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(flex: 2),

              // Action buttons - like call screen
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Dismiss button
                    _buildActionButton(
                      icon: Icons.close,
                      label: 'Dismiss',
                      color: Colors.red,
                      onTap: _dismiss,
                    ),

                    // Take button (main action)
                    _buildActionButton(
                      icon: Icons.check,
                      label: 'Take',
                      color: Colors.green,
                      isMain: true,
                      onTap: _takeMedicine,
                    ),

                    // Snooze button
                    _buildActionButton(
                      icon: Icons.snooze,
                      label: 'Snooze',
                      color: Colors.orange,
                      onTap: _snooze,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Swipe up or tap an action',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isMain = false,
  }) {
    final size = isMain ? 80.0 : 64.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: isMain ? 40 : 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
