import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class CPRSimulationScreen extends StatefulWidget {
  const CPRSimulationScreen({super.key});

  @override
  State<CPRSimulationScreen> createState() => _CPRSimulationScreenState();
}

class _CPRSimulationScreenState extends State<CPRSimulationScreen>
    with TickerProviderStateMixin {
  // Simulation steps
  final List<Map<String, dynamic>> _steps = [
    {
      'step': 1,
      'title': 'Check Responsiveness',
      'instruction': 'Tap the person\'s shoulder and shout "Are you okay?"',
      'icon': Icons.touch_app,
      'action': 'tap', // tap to confirm
      'voiceText':
          'Step 1. Check responsiveness. Tap the person\'s shoulder firmly and shout: Are you okay?',
    },
    {
      'step': 2,
      'title': 'Call for Help',
      'instruction': 'Call 102 emergency services immediately',
      'icon': Icons.phone,
      'action': 'tap',
      'voiceText':
          'Step 2. Call for help. Call 102 emergency services immediately. Ask someone to get an AED.',
    },
    {
      'step': 3,
      'title': 'Position Your Hands',
      'instruction': 'Place heel of hand on center of chest, between nipples',
      'icon': Icons.back_hand,
      'action': 'tap',
      'voiceText':
          'Step 3. Position your hands. Place the heel of your hand on the center of the chest, between the nipples. Place your other hand on top.',
    },
    {
      'step': 4,
      'title': 'Chest Compressions',
      'instruction':
          'Push hard and fast! Tap the circle to count compressions.',
      'icon': Icons.favorite,
      'action': 'compress', // tap to count compressions
      'target': 30,
      'voiceText':
          'Step 4. Begin chest compressions. Push hard and fast at 100 to 120 compressions per minute. Compress at least 2 inches deep. Tap the screen to count.',
    },
    {
      'step': 5,
      'title': 'Continue CPR',
      'instruction': 'Keep going until help arrives!',
      'icon': Icons.repeat,
      'action': 'complete',
      'voiceText':
          'Step 5. Continue CPR. Do not stop until emergency services arrive or the person starts breathing. Great job!',
    },
  ];

  int _currentStepIndex = 0;
  int _compressionCount = 0;
  bool _isPaused = false;
  bool _voiceEnabled = true;
  bool _isCompleted = false;
  int _bpmDisplay = 0;
  double _depthDisplay = 0.0;
  String _feedbackText = '';
  Color _feedbackColor = Colors.green;

  late AnimationController _pulseController;
  late AnimationController _tapFeedbackController;
  FlutterTts? _flutterTts;
  Timer? _bpmTimer;
  List<DateTime> _compressionTimes = [];

  Map<String, dynamic> get _currentStep => _steps[_currentStepIndex];

  @override
  void initState() {
    super.initState();
    _initTts();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    )..repeat(reverse: true);

    _tapFeedbackController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Start with first step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentStep();
    });
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts?.setLanguage('en-US');
    await _flutterTts?.setSpeechRate(0.45);
    await _flutterTts?.setVolume(1.0);
    await _flutterTts?.setPitch(1.0);
  }

  Future<void> _speakCurrentStep() async {
    if (_voiceEnabled && _flutterTts != null) {
      await _flutterTts?.speak(_currentStep['voiceText'] ?? '');
    }
  }

  void _handleTap() {
    if (_isPaused || _isCompleted) return;

    HapticFeedback.mediumImpact();

    final action = _currentStep['action'];

    if (action == 'compress') {
      _handleCompression();
    } else if (action == 'tap' || action == 'complete') {
      _goToNextStep();
    }
  }

  void _handleCompression() {
    setState(() {
      _compressionCount++;
      _compressionTimes.add(DateTime.now());

      // Calculate BPM from last few compressions
      if (_compressionTimes.length >= 3) {
        final recent = _compressionTimes.sublist(_compressionTimes.length - 3);
        final totalMs = recent.last.difference(recent.first).inMilliseconds;
        if (totalMs > 0) {
          _bpmDisplay = ((2 / totalMs) * 60000).round();
        }
      }

      // Simulate depth variation
      _depthDisplay = 1.8 + ((_compressionCount % 5) * 0.15);

      // Update feedback
      if (_bpmDisplay >= 100 && _bpmDisplay <= 120) {
        _feedbackText = 'Great rhythm!';
        _feedbackColor = Colors.green;
      } else if (_bpmDisplay > 120) {
        _feedbackText = 'Slow down a bit';
        _feedbackColor = Colors.orange;
      } else if (_bpmDisplay > 0 && _bpmDisplay < 100) {
        _feedbackText = 'Push faster!';
        _feedbackColor = Colors.orange;
      }

      if (_depthDisplay >= 2.0 && _depthDisplay <= 2.4) {
        if (_feedbackText.isEmpty) _feedbackText = 'Good depth!';
      } else if (_depthDisplay < 2.0) {
        _feedbackText = 'Push harder!';
        _feedbackColor = Colors.orange;
      }
    });

    // Tap animation
    _tapFeedbackController
        .forward()
        .then((_) => _tapFeedbackController.reverse());

    // Check if target reached
    final target = _currentStep['target'] ?? 30;
    if (_compressionCount >= target) {
      if (_voiceEnabled) {
        _flutterTts?.speak('Excellent! 30 compressions complete.');
      }
      Future.delayed(const Duration(seconds: 2), _goToNextStep);
    } else if (_compressionCount == 15 && _voiceEnabled) {
      _flutterTts?.speak('Halfway there! Keep going!');
    }
  }

  void _goToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _compressionCount = 0;
        _compressionTimes.clear();
        _bpmDisplay = 0;
        _depthDisplay = 0;
        _feedbackText = '';
      });
      _speakCurrentStep();
    } else {
      setState(() => _isCompleted = true);
      if (_voiceEnabled) {
        _flutterTts?.speak(
            'Simulation complete. You did great! In a real emergency, continue until help arrives.');
      }
    }
  }

  void _goToPrevStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        _compressionCount = 0;
        _compressionTimes.clear();
      });
      _speakCurrentStep();
    }
  }

  void _restartSimulation() {
    setState(() {
      _currentStepIndex = 0;
      _compressionCount = 0;
      _compressionTimes.clear();
      _isCompleted = false;
      _bpmDisplay = 0;
      _depthDisplay = 0;
      _feedbackText = '';
    });
    _speakCurrentStep();
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _pulseController.stop();
      _flutterTts?.stop();
    } else {
      _pulseController.repeat(reverse: true);
      _speakCurrentStep();
    }
  }

  void _toggleVoice() {
    setState(() => _voiceEnabled = !_voiceEnabled);
    if (!_voiceEnabled) {
      _flutterTts?.stop();
    } else {
      _speakCurrentStep();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapFeedbackController.dispose();
    _flutterTts?.stop();
    _bpmTimer?.cancel();
    super.dispose();
  }

  void _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Silent fail - emergency screen handles this
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompressionStep = _currentStep['action'] == 'compress';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.cprSimulation),
        actions: [
          TextButton.icon(
            onPressed: () => _makeCall('102'),
            icon: const Icon(Icons.phone, color: Colors.red),
            label: const Text('Call 102',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isCompleted
          ? _buildCompletionScreen()
          : Column(
              children: [
                // Step indicators
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        _steps.length,
                        (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _currentStepIndex ? 32 : 24,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i <= _currentStepIndex
                                    ? AppColors.primary
                                    : Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )),
                  ),
                ),

                // Step title
                Text('Step ${_currentStep['step']} of ${_steps.length}',
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                const SizedBox(height: 8),
                Text(_currentStep['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(_currentStep['instruction'],
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      textAlign: TextAlign.center),
                ),

                const SizedBox(height: 24),

                // Main interaction area
                Expanded(
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse animation
                        if (!_isPaused)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) => Container(
                              width: 200 + (_pulseController.value * 30),
                              height: 200 + (_pulseController.value * 30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(
                                      0.4 - (_pulseController.value * 0.3)),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),

                        // Main circle (tap target)
                        ScaleTransition(
                          scale: Tween(begin: 1.0, end: 0.9)
                              .animate(_tapFeedbackController),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: _isPaused
                                  ? Colors.grey.shade800
                                  : AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _isPaused
                                      ? Colors.grey
                                      : AppColors.primary,
                                  width: 4),
                              boxShadow: _isPaused
                                  ? null
                                  : [
                                      BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.3),
                                          blurRadius: 20),
                                    ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_currentStep['icon'],
                                    color:
                                        _isPaused ? Colors.grey : Colors.white,
                                    size: 48),
                                if (isCompressionStep) ...[
                                  const SizedBox(height: 8),
                                  Text('TAP',
                                      style: TextStyle(
                                          color: _isPaused
                                              ? Colors.grey
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Feedback badge
                        if (_feedbackText.isNotEmpty)
                          Positioned(
                            top: 20,
                            right: 40,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _feedbackColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _feedbackColor.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: _feedbackColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(_feedbackText,
                                      style: TextStyle(
                                          color: _feedbackColor,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),

                        // Navigation arrows (for non-compression steps)
                        if (!isCompressionStep) ...[
                          if (_currentStepIndex > 0)
                            Positioned(
                              left: 20,
                              child: IconButton(
                                onPressed: _goToPrevStep,
                                icon: const Icon(Icons.arrow_back_ios,
                                    color: Colors.white54),
                              ),
                            ),
                          Positioned(
                            right: 20,
                            child: IconButton(
                              onPressed: _goToNextStep,
                              icon: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white54),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Stats (for compression step)
                if (isCompressionStep) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBox(
                            'Rate',
                            _bpmDisplay > 0 ? '$_bpmDisplay BPM' : '--',
                            _bpmDisplay >= 100 && _bpmDisplay <= 120
                                ? Colors.green
                                : Colors.orange),
                        _buildStatBox(
                            'Depth',
                            _depthDisplay > 0
                                ? '${_depthDisplay.toStringAsFixed(1)} in'
                                : '--',
                            _depthDisplay >= 2 && _depthDisplay <= 2.4
                                ? Colors.green
                                : Colors.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '$_compressionCount / ${_currentStep['target'] ?? 30}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700)),
                            const Text('compressions',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _compressionCount /
                                (_currentStep['target'] ?? 30),
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon:
                            _voiceEnabled ? Icons.volume_up : Icons.volume_off,
                        label: 'Voice',
                        isActive: _voiceEnabled,
                        onTap: _toggleVoice,
                      ),
                      GestureDetector(
                        onTap: _togglePause,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _isPaused ? Colors.green : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: (_isPaused
                                          ? Colors.green
                                          : AppColors.primary)
                                      .withOpacity(0.4),
                                  blurRadius: 15),
                            ],
                          ),
                          child: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.white,
                              size: 36),
                        ),
                      ),
                      _buildControlButton(
                        icon: Icons.restart_alt,
                        label: 'Restart',
                        isActive: false,
                        onTap: _restartSimulation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 32),
            const Text('Simulation Complete!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Great job! You completed all 5 steps of Adult CPR training.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _restartSimulation,
              icon: const Icon(Icons.replay),
              label: const Text('Practice Again'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Simulations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildControlButton(
      {required IconData icon,
      required String label,
      required bool isActive,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: isActive ? Colors.white : Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
