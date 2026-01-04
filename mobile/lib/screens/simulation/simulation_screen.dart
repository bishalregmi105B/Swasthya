import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';

/// Simulation Screen - loads data from API with bilingual support
class SimulationScreen extends StatefulWidget {
  final String simulationType;

  const SimulationScreen({super.key, required this.simulationType});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with TickerProviderStateMixin {
  // State
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _simulationData;
  List<dynamic> _steps = [];

  int _currentStepIndex = 0;
  int _compressionCount = 0;
  bool _isPaused = false;
  bool _voiceEnabled = true;
  bool _isCompleted = false;
  String _language = 'en';
  int _bpmDisplay = 0;
  double _depthDisplay = 0.0;
  String _feedbackText = '';
  Color _feedbackColor = Colors.green;

  late AnimationController _pulseController;
  late AnimationController _tapFeedbackController;
  FlutterTts? _flutterTts;
  List<DateTime> _compressionTimes = [];

  Map<String, dynamic> get _currentStep =>
      _steps.isNotEmpty ? _steps[_currentStepIndex] : {};
  Color get _simColor => _parseColor(_simulationData?['color'] ?? '#136dec');

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _initTts();
    _loadSimulation();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    )..repeat(reverse: true);

    _tapFeedbackController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  void _loadLanguagePreference() {
    final box = Hive.box('settings');
    _language = box.get('simulation_language', defaultValue: 'en');
  }

  void _saveLanguagePreference() {
    final box = Hive.box('settings');
    box.put('simulation_language', _language);
  }

  Future<void> _loadSimulation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await apiService.getSimulation(widget.simulationType,
          lang: _language);

      // Cache for offline use
      await OfflineCacheService.cacheData(
          'simulation_${widget.simulationType}_$_language', data);

      setState(() {
        _simulationData = data['simulation'];
        _steps = _simulationData?['steps'] ?? [];
        _isLoading = false;
      });
      _speakCurrentStep();
    } catch (e) {
      // Try loading from cache
      final cached = OfflineCacheService.getCachedData(
          'simulation_${widget.simulationType}_$_language');
      if (cached != null) {
        setState(() {
          _simulationData = cached['simulation'];
          _steps = _simulationData?['steps'] ?? [];
          _isLoading = false;
        });
        _speakCurrentStep();
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _setTtsLanguage();
  }

  Future<void> _setTtsLanguage() async {
    await _flutterTts?.setLanguage(_language == 'ne' ? 'ne-NP' : 'en-US');
    await _flutterTts?.setSpeechRate(_language == 'ne' ? 0.4 : 0.45);
    await _flutterTts?.setVolume(1.0);
  }

  void _toggleLanguage() async {
    await _flutterTts?.stop();
    setState(() => _language = _language == 'en' ? 'ne' : 'en');
    _saveLanguagePreference();
    await _setTtsLanguage();
    // Reload simulation with new language
    _loadSimulation();
  }

  Future<void> _speakCurrentStep() async {
    if (_voiceEnabled && _flutterTts != null && _currentStep.isNotEmpty) {
      final text =
          _currentStep['voice_text'] ?? _currentStep['instruction'] ?? '';
      await _flutterTts?.speak(text);
    }
  }

  void _handleTap() {
    if (_isPaused || _isCompleted || _steps.isEmpty) return;
    HapticFeedback.mediumImpact();

    final stepType = _currentStep['step_type'] ?? 'info';
    if (stepType == 'compress' || stepType == 'timed') {
      _handleCompression();
    } else {
      _goToNextStep();
    }
  }

  void _handleCompression() {
    setState(() {
      _compressionCount++;
      _compressionTimes.add(DateTime.now());

      if (_compressionTimes.length >= 3) {
        final recent = _compressionTimes.sublist(_compressionTimes.length - 3);
        final totalMs = recent.last.difference(recent.first).inMilliseconds;
        if (totalMs > 0) _bpmDisplay = ((2 / totalMs) * 60000).round();
      }

      _depthDisplay = 1.8 + ((_compressionCount % 5) * 0.15);

      final goodFeedback = _currentStep['ai_feedback_good'];
      final adjustFeedback = _currentStep['ai_feedback_adjust'];

      if (_bpmDisplay >= 100 && _bpmDisplay <= 120) {
        _feedbackText =
            goodFeedback ?? (_language == 'ne' ? 'राम्रो!' : 'Great!');
        _feedbackColor = Colors.green;
      } else if (_bpmDisplay > 120) {
        _feedbackText = _language == 'ne' ? 'बिस्तारै!' : 'Slow down!';
        _feedbackColor = Colors.orange;
      } else if (_bpmDisplay > 0 && _bpmDisplay < 100) {
        _feedbackText =
            adjustFeedback ?? (_language == 'ne' ? 'छिटो!' : 'Faster!');
        _feedbackColor = Colors.orange;
      }
    });

    _tapFeedbackController
        .forward()
        .then((_) => _tapFeedbackController.reverse());

    final target = _currentStep['target_value'] ?? 30;
    if (_compressionCount >= target) {
      if (_voiceEnabled)
        _flutterTts?.speak(_language == 'ne' ? 'पूरा!' : 'Complete!');
      Future.delayed(const Duration(seconds: 2), _goToNextStep);
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
      if (_voiceEnabled)
        _flutterTts?.speak(_language == 'ne' ? 'पूरा!' : 'Complete!');
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
    if (!_voiceEnabled)
      _flutterTts?.stop();
    else {
      _speakCurrentStep();
    }
  }

  /// Open AI Call bottom sheet with simulation context
  void _openAICall() {
    final simTitle = _simulationData?['title'] ?? 'Emergency Training';
    final stepTitle = _currentStep['title'] ?? '';
    final stepInstruction = _currentStep['instruction'] ?? '';
    final stepNum = _currentStepIndex + 1;
    final totalSteps = _steps.length;

    // Build context for AI
    final context = '''
I am currently practicing: $simTitle
Current step: $stepNum of $totalSteps - $stepTitle
Instruction: $stepInstruction

Please help me with this emergency procedure. You can guide me step by step, answer questions about the technique, or provide additional tips.''';

    showLiveAICallBottomSheet(
      context: this.context,
      config: LiveAICallConfig(
        specialist: 'Emergency First Aid Trainer',
        patientContext: context,
        systemPrompt:
            '''You are an AI emergency first aid trainer helping a user practice $simTitle.
They are on step $stepNum: $stepTitle.
Provide clear, concise guidance. Use simple language. Be encouraging.
If they ask questions, answer based on standard first aid protocols.
If they seem confused, offer to explain the current step again.''',
        language:
            _language == 'ne' ? AICallLanguage.nepali : AICallLanguage.english,
      ),
      title: '$simTitle - AI Guide',
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getIcon(String? name) {
    const icons = {
      'favorite': Icons.favorite,
      'emergency': Icons.emergency,
      'healing': Icons.healing,
      'local_fire_department': Icons.local_fire_department,
      'phone': Icons.phone,
      'touch_app': Icons.touch_app,
      'back_hand': Icons.back_hand,
      'repeat': Icons.repeat,
      'help_outline': Icons.help_outline,
      'accessibility_new': Icons.accessibility_new,
      'check_circle': Icons.check_circle,
      'wash': Icons.wash,
      'bloodtype': Icons.bloodtype,
      'water_drop': Icons.water_drop,
      'medication': Icons.medication,
      'water': Icons.water,
      'watch': Icons.watch,
      'do_not_touch': Icons.do_not_touch,
      'local_hospital': Icons.local_hospital,
    };
    return icons[name] ?? Icons.info;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapFeedbackController.dispose();
    _flutterTts?.stop();
    super.dispose();
  }

  void _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _simulationData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load simulation',
                  style: TextStyle(color: Colors.grey.shade400)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadSimulation, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final isCompressionStep =
        ['compress', 'timed'].contains(_currentStep['step_type']);
    final title = _simulationData?['title'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _toggleLanguage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_language == 'en' ? '🇳🇵 NE' : '🇬🇧 EN',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
          TextButton.icon(
            onPressed: () => _makeCall('102'),
            icon: const Icon(Icons.phone, color: Colors.red, size: 16),
            label: const Text('102',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        _steps.length,
                        (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _currentStepIndex ? 28 : 18,
                              height: 5,
                              decoration: BoxDecoration(
                                color: i <= _currentStepIndex
                                    ? _simColor
                                    : Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            )),
                  ),
                ),

                // Step info
                Text('${_currentStepIndex + 1}/${_steps.length}',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_currentStep['title'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
                  child: Text(_currentStep['instruction'] ?? '',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      textAlign: TextAlign.center),
                ),

                // Animation Area
                Expanded(
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Lottie animation
                        if (_currentStep['animation_url'] != null)
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: Lottie.network(
                              _currentStep['animation_url'],
                              animate: !_isPaused,
                              repeat: true,
                              errorBuilder: (ctx, e, s) => _buildIconFallback(),
                            ),
                          )
                        else
                          _buildIconFallback(),

                        // Compression overlay
                        if (isCompressionStep) ...[
                          Positioned(
                            bottom: 20,
                            child: ScaleTransition(
                              scale: Tween(begin: 1.0, end: 0.88)
                                  .animate(_tapFeedbackController),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: _simColor.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: _simColor.withOpacity(0.5),
                                        blurRadius: 20)
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('$_compressionCount',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        _language == 'ne'
                                            ? 'थिच्नुहोस्'
                                            : 'TAP',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Feedback badge
                        if (_feedbackText.isNotEmpty)
                          Positioned(
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: _feedbackColor,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(_feedbackText,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ),

                        // Navigation arrows
                        if (!isCompressionStep) ...[
                          if (_currentStepIndex > 0)
                            Positioned(
                                left: 8,
                                child: IconButton(
                                    onPressed: _goToPrevStep,
                                    icon: const Icon(Icons.chevron_left,
                                        color: Colors.white38, size: 36))),
                          Positioned(
                              right: 8,
                              child: IconButton(
                                  onPressed: _goToNextStep,
                                  icon: const Icon(Icons.chevron_right,
                                      color: Colors.white38, size: 36))),
                        ],
                      ],
                    ),
                  ),
                ),

                // Stats for compression
                if (isCompressionStep) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip(
                          'BPM',
                          _bpmDisplay > 0 ? '$_bpmDisplay' : '--',
                          _bpmDisplay >= 100 && _bpmDisplay <= 120
                              ? Colors.green
                              : Colors.orange),
                      const SizedBox(width: 20),
                      _buildStatChip(
                          'DEPTH',
                          _depthDisplay > 0
                              ? '${_depthDisplay.toStringAsFixed(1)}"'
                              : '--',
                          _depthDisplay >= 2 ? Colors.green : Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _compressionCount /
                            (_currentStep['target_value'] ?? 30),
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade800,
                        color: _simColor,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlBtn(
                          _voiceEnabled ? Icons.volume_up : Icons.volume_off,
                          _voiceEnabled,
                          _toggleVoice),
                      GestureDetector(
                        onTap: _togglePause,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _isPaused ? Colors.green : _simColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.white,
                              size: 28),
                        ),
                      ),
                      _buildControlBtn(
                          Icons.restart_alt, false, _restartSimulation),
                      _buildControlBtn(Icons.support_agent, false, _openAICall),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIconFallback() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: _simColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: _simColor.withOpacity(0.4), width: 3),
      ),
      child:
          Icon(_getIcon(_simulationData?['icon']), color: _simColor, size: 60),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 24),
            Text(_language == 'ne' ? 'पूरा भयो!' : 'Complete!',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_language == 'ne' ? 'राम्रो काम!' : 'Great job!',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _restartSimulation,
              icon: const Icon(Icons.replay),
              label: Text(_language == 'ne' ? 'फेरि' : 'Again'),
            ),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () => context.pop(),
                child: Text(_language == 'ne' ? 'फिर्ता' : 'Back',
                    style: const TextStyle(color: Colors.white54))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildControlBtn(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child:
            Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
      ),
    );
  }
}
