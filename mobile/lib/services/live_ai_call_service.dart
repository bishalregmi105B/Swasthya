import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

/// Available languages for AI medical consultation
enum AICallLanguage {
  english('en-US', 'English', '🇺🇸'),
  nepali('ne-NP', 'नेपाली (Nepali)', '🇳🇵'),
  hindi('hi-IN', 'हिन्दी (Hindi)', '🇮🇳'),
  spanish('es-ES', 'Español', '🇪🇸'),
  french('fr-FR', 'Français', '🇫🇷'),
  german('de-DE', 'Deutsch', '🇩🇪');

  const AICallLanguage(this.code, this.displayName, this.flag);

  final String code;
  final String displayName;
  final String flag;

  static AICallLanguage fromCode(String code) {
    return AICallLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AICallLanguage.english,
    );
  }
}

/// Configuration for Live AI Medical Call
class LiveAICallConfig {
  final String? specialist;
  final String? patientContext;
  final List<Map<String, dynamic>>? conversationHistory;
  final String? systemPrompt;
  final AICallLanguage language;

  const LiveAICallConfig({
    this.specialist,
    this.patientContext,
    this.conversationHistory,
    this.systemPrompt,
    this.language = AICallLanguage.english,
  });

  LiveAICallConfig copyWith({
    String? specialist,
    String? patientContext,
    List<Map<String, dynamic>>? conversationHistory,
    String? systemPrompt,
    AICallLanguage? language,
  }) {
    return LiveAICallConfig(
      specialist: specialist ?? this.specialist,
      patientContext: patientContext ?? this.patientContext,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
        if (specialist != null) 'specialist': specialist,
        if (patientContext != null) 'patient_context': patientContext,
        if (conversationHistory != null)
          'conversation_history': conversationHistory,
        if (systemPrompt != null) 'system_prompt': systemPrompt,
        'language': language.code,
        'language_name': language.displayName,
      };
}

/// State of the Live AI Call
enum LiveAICallState {
  idle,
  connecting,
  calibrating,
  ready,
  listening,
  processing,
  playingResponse,
  error,
  disconnected,
}

/// Live AI Call Service - Handles voice-based medical consultations
class LiveAICallService extends ChangeNotifier {
  static LiveAICallService? _instance;
  static LiveAICallService get instance => _instance ??= LiveAICallService._();

  LiveAICallService._();

  // State
  LiveAICallState _state = LiveAICallState.idle;
  String _statusMessage = 'Ready to start consultation';
  bool _isConnected = false;
  String? _sessionId;
  Duration _callDuration = Duration.zero;
  List<Map<String, dynamic>> _conversationHistory = [];
  String _recognizedText = '';
  String _aiResponse = '';

  // Session metrics
  int _totalInteractions = 0;
  Map<String, dynamic>? _sessionMetrics;

  // Voice detection
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  double _soundLevel = 0.0;

  // Enhanced voice detection
  double _backgroundNoise = 0.0;
  final List<double> _soundHistory = [];
  bool _isCalibrating = false;
  bool _isCalibrated = false;
  int _silentFrames = 0;
  int _speakingFrames = 0;

  // Audio playback
  late AudioPlayer _audioPlayer;
  bool _audioPlayerInitialized = false;
  bool _isPlayingResponse = false;
  bool _isResumeScheduled = false;
  Timer? _resumeListeningTimer;

  // Timers
  Timer? _callTimer;
  Timer? _keepAliveTimer;
  Timer? _voiceActivityTimer;
  Timer? _calibrationTimer;

  // Configuration
  LiveAICallConfig? _config;

  // Constants for voice detection
  static const double _speakingThreshold = 0.35;
  static const double _silenceThreshold = 0.25;
  static const int _minSpeakingFrames = 3;
  static const int _minSilentFrames = 5;

  // Getters
  LiveAICallState get state => _state;
  String get statusMessage => _statusMessage;
  bool get isConnected => _isConnected;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isPlayingResponse => _isPlayingResponse;
  bool get isCalibrating => _isCalibrating;
  Duration get callDuration => _callDuration;
  List<Map<String, dynamic>> get conversationHistory =>
      List.unmodifiable(_conversationHistory);
  String get recognizedText => _recognizedText;
  String get aiResponse => _aiResponse;
  double get soundLevel => _soundLevel;
  int get totalInteractions => _totalInteractions;
  Map<String, dynamic>? get sessionMetrics => _sessionMetrics;
  bool get isCallActive =>
      _state != LiveAICallState.idle && _state != LiveAICallState.error;

  /// Get API base URL from Hive
  String get _baseUrl {
    try {
      final box = Hive.box('appSettings');
      return box.get('apiBaseUrl',
          defaultValue: 'https://aacademyapi.ashlya.com');
    } catch (e) {
      return 'https://aacademyapi.ashlya.com';
    }
  }

  /// Get auth token from Hive
  String get _authToken {
    try {
      final box = Hive.box('auth');
      return box.get('accessToken', defaultValue: '');
    } catch (e) {
      return '';
    }
  }

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      print('LiveAICallService: Initializing...');

      // Initialize speech-to-text
      _speech = stt.SpeechToText();
      await _initializeSpeech();

      // Initialize audio player
      _audioPlayer = AudioPlayer();
      await _setupAudioPlayer();

      print('LiveAICallService: Initialized successfully');
      return true;
    } catch (e) {
      print('LiveAICallService: Initialization failed: $e');
      _updateState(LiveAICallState.error, 'Initialization failed: $e');
      return false;
    }
  }

  /// Start a live AI medical consultation
  Future<bool> startCall(LiveAICallConfig config,
      {String? continueSessionId}) async {
    if (_state != LiveAICallState.idle) {
      print('LiveAICallService: Call already in progress');
      return false;
    }

    if (!_speechEnabled) {
      _updateState(LiveAICallState.error, 'Speech recognition not available');
      return false;
    }

    try {
      _config = config;
      _updateState(LiveAICallState.connecting, 'Connecting to AI Doctor...');

      // Create session
      await _createSession(continueSessionId: continueSessionId);

      _updateState(LiveAICallState.calibrating, 'Calibrating microphone...');

      // Start calibration
      _calibrateBackgroundNoise();

      // Start call timer
      _startCallTimer();

      // Start keep-alive timer
      _startKeepAliveTimer();

      // Wait for calibration then start listening
      Future.delayed(const Duration(seconds: 3), () {
        if (_state != LiveAICallState.error && _state != LiveAICallState.idle) {
          _updateState(
              LiveAICallState.ready, 'Connected - Describe your symptoms');
          _startListening();
        }
      });

      return true;
    } catch (e) {
      print('LiveAICallService: Failed to start call: $e');
      _updateState(LiveAICallState.error, 'Connection failed: $e');
      return false;
    }
  }

  /// End the current consultation
  Future<void> endCall() async {
    print('LiveAICallService: Ending call...');

    _updateState(LiveAICallState.disconnected, 'Consultation ended');

    // Stop all activities
    await _stopListening();
    _callTimer?.cancel();
    _keepAliveTimer?.cancel();
    _calibrationTimer?.cancel();
    _voiceActivityTimer?.cancel();

    // Close HTTP session
    if (_sessionId != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/api/ai-sathi/live-call/end'),
          headers: {
            'Content-Type': 'application/json',
            if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
          },
          body: jsonEncode({'session_id': _sessionId}),
        );
      } catch (e) {
        print('LiveAICallService: Error ending session: $e');
      }
      _sessionId = null;
    }

    // Stop audio playback
    if (_audioPlayerInitialized) {
      await _audioPlayer.stop();
    }

    // Reset state
    _isConnected = false;
    _callDuration = Duration.zero;
    _conversationHistory.clear();
    _recognizedText = '';
    _aiResponse = '';
    _config = null;
    _totalInteractions = 0;
    _sessionMetrics = null;

    // Reset voice detection state
    _isSpeaking = false;
    _isListening = false;
    _isCalibrating = false;
    _isCalibrated = false;
    _soundLevel = 0.0;
    _backgroundNoise = 0.0;
    _silentFrames = 0;
    _speakingFrames = 0;
    _soundHistory.clear();
    _isResumeScheduled = false;
    _resumeListeningTimer?.cancel();

    _updateState(LiveAICallState.idle, 'Ready to start consultation');
    notifyListeners();
  }

  /// Toggle mute/unmute
  Future<void> toggleMute() async {
    if (_isListening) {
      await _stopListening();
    } else if (_state == LiveAICallState.ready ||
        _state == LiveAICallState.listening) {
      await _resetAudioPlayerForListening();
      await _startListening();
    }
  }

  /// Stop AI audio and resume listening
  Future<void> stopAIAndResumeListen() async {
    if (_isPlayingResponse) {
      try {
        await _audioPlayer.stop();
        _isPlayingResponse = false;
        _updateState(LiveAICallState.listening, 'Listening...');
        await _startListening();
        print('LiveAICallService: AI audio stopped, resumed listening');
      } catch (e) {
        print('LiveAICallService: Error stopping AI audio: $e');
      }
    }
  }

  /// Force resume listening
  Future<void> forceResumeListening() async {
    if (!_isConnected || _isListening || _state == LiveAICallState.processing) {
      return;
    }

    try {
      print('LiveAICallService: Force resuming listening...');
      if (_isPlayingResponse) {
        await _audioPlayer.stop();
        _isPlayingResponse = false;
      }
      await _resetAudioPlayerForListening();
      _isSpeaking = false;
      _isListening = false;
      _updateState(LiveAICallState.ready, 'Listening...');
      await _startListening();
    } catch (e) {
      print('LiveAICallService: Error in force resume: $e');
    }
  }

  @override
  void dispose() {
    endCall();
    _callTimer?.cancel();
    _keepAliveTimer?.cancel();
    _voiceActivityTimer?.cancel();
    _calibrationTimer?.cancel();
    _resumeListeningTimer?.cancel();
    if (_audioPlayerInitialized) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  // Private methods
  void _updateState(LiveAICallState newState, String message) {
    _state = newState;
    _statusMessage = message;
    notifyListeners();
  }

  Future<void> _initializeSpeech() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _updateState(LiveAICallState.error, 'Microphone permission denied');
        return;
      }

      bool available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: true,
      );

      _speechEnabled = available;
      if (!available) {
        _updateState(LiveAICallState.error, 'Speech not available');
      }
    } catch (e) {
      print('LiveAICallService: Error initializing speech: $e');
      _updateState(LiveAICallState.error, 'Error initializing speech');
    }
  }

  Future<void> _setupAudioPlayer() async {
    try {
      // Main player state listener
      _audioPlayer.playerStateStream.listen((state) {
        print(
            'LiveAICallService: Player state: playing=${state.playing}, processing=${state.processingState}');

        final wasPlaying = _isPlayingResponse;
        _isPlayingResponse = state.playing;

        // Handle audio completion
        if (_isConnected &&
            !_isResumeScheduled &&
            ((state.processingState == ProcessingState.completed &&
                    !state.playing) ||
                (wasPlaying && !state.playing))) {
          print(
              'LiveAICallService: Audio completed via state listener, scheduling resume');
          _isPlayingResponse = false;
          _scheduleListeningResume();
        }
        // Handle case where audio processing completed but still shows as playing
        else if (_isConnected &&
            !_isResumeScheduled &&
            state.processingState == ProcessingState.completed &&
            state.playing &&
            _isPlayingResponse) {
          print(
              'LiveAICallService: Audio processing completed but still playing - force scheduling resume');
          _scheduleListeningResume();
        }

        notifyListeners();
      });

      // Backup position listener for catching audio completion
      _audioPlayer.positionStream.listen((position) {
        if (_isPlayingResponse &&
            !_isResumeScheduled &&
            _audioPlayer.duration != null) {
          final duration = _audioPlayer.duration!;
          final remaining = duration - position;

          // Trigger when audio is almost done (within 100ms)
          if (remaining.inMilliseconds <= 100 &&
              remaining.inMilliseconds >= 0) {
            print(
                'LiveAICallService: Audio nearly completed via position stream');
            _scheduleListeningResume();
          }
        }
      });

      _audioPlayerInitialized = true;
      print('LiveAICallService: Audio player setup complete');
    } catch (e) {
      print('LiveAICallService: Error setting up audio player: $e');
      rethrow;
    }
  }

  void _onSpeechStatus(String status) {
    print('LiveAICallService: Speech status: $status');
    if (status == 'listening') {
      _isListening = true;
    } else if (status == 'notListening') {
      _isListening = false;
      _isSpeaking = false;
      _soundLevel = 0.0;
    }
    notifyListeners();
  }

  void _onSpeechError(dynamic error) {
    print('LiveAICallService: Speech error: $error');
    _isListening = false;
    _isSpeaking = false;

    if (_isConnected && _state != LiveAICallState.processing) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_isConnected &&
            !_isListening &&
            !_isPlayingResponse &&
            _state != LiveAICallState.processing) {
          _startListening();
        }
      });
    }
    notifyListeners();
  }

  Future<void> _createSession({String? continueSessionId}) async {
    try {
      final requestBody = _config?.toJson() ?? {};
      if (continueSessionId != null) {
        requestBody['continue_session_id'] = continueSessionId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai-sathi/live-call/start'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['session_id'];
        _isConnected = true;

        if (data['session_info'] != null) {
          _totalInteractions = data['session_info']['total_interactions'] ?? 0;
        }

        // Play greeting
        if (data['greeting'] != null) {
          _aiResponse = data['greeting'];
        }

        print('LiveAICallService: Created session: $_sessionId');
      } else {
        throw Exception('Failed to create session: ${response.statusCode}');
      }
    } catch (e) {
      print('LiveAICallService: Session creation error: $e');
      rethrow;
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isConnected) {
        _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
        notifyListeners();
      }
    });
  }

  void _startKeepAliveTimer() {
    _keepAliveTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_sessionId != null && _isConnected) {
        try {
          await http.post(
            Uri.parse('$_baseUrl/api/ai-sathi/live-call/keep-alive'),
            headers: {
              'Content-Type': 'application/json',
              if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
            },
            body: jsonEncode({'session_id': _sessionId}),
          );
        } catch (e) {
          print('LiveAICallService: Keep-alive error: $e');
        }
      }
    });
  }

  void _calibrateBackgroundNoise() {
    _isCalibrating = true;
    _soundHistory.clear();

    _calibrationTimer = Timer(const Duration(seconds: 2), () {
      if (_soundHistory.isNotEmpty) {
        _backgroundNoise =
            _soundHistory.reduce((a, b) => a + b) / _soundHistory.length;
        _backgroundNoise = math.max(0.1, _backgroundNoise);
      } else {
        _backgroundNoise = 0.25;
      }
      _isCalibrating = false;
      _isCalibrated = true;
      print(
          'LiveAICallService: Calibrated background noise: $_backgroundNoise');
      notifyListeners();
    });
  }

  Future<void> _startListening() async {
    if (!_speechEnabled || _isListening || _isPlayingResponse) {
      return;
    }

    try {
      print('LiveAICallService: Starting speech recognition...');
      await _resetAudioPlayerForListening();

      await _speech.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: _onSoundLevelChange,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        localeId: _config?.language.code ?? 'en-US',
      );

      _startVoiceActivityMonitoring();
    } catch (e) {
      print('LiveAICallService: Error starting speech recognition: $e');
      if (_isConnected && _state != LiveAICallState.processing) {
        Future.delayed(const Duration(seconds: 3), () {
          if (_isConnected && !_isListening && !_isPlayingResponse) {
            _startListening();
          }
        });
      }
    }
  }

  void _startVoiceActivityMonitoring() {
    _voiceActivityTimer?.cancel();
    _voiceActivityTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isListening || _isPlayingResponse) {
        timer.cancel();
        return;
      }

      // Detect speaking based on sound level
      final threshold = _isCalibrated
          ? (_backgroundNoise + _speakingThreshold)
          : _speakingThreshold;

      if (_soundLevel > threshold) {
        _speakingFrames++;
        _silentFrames = 0;

        if (_speakingFrames >= _minSpeakingFrames && !_isSpeaking) {
          _isSpeaking = true;
          _updateState(LiveAICallState.listening, 'Listening to you...');
        }
      } else {
        _silentFrames++;

        if (_silentFrames >= _minSilentFrames && _isSpeaking) {
          _isSpeaking = false;
          _speakingFrames = 0;
        }
      }
    });
  }

  void _onSoundLevelChange(double level) {
    _soundLevel = math.max(0, (level + 50) / 50); // Normalize from dB
    _soundHistory.add(_soundLevel);
    if (_soundHistory.length > 50) {
      _soundHistory.removeAt(0);
    }
    notifyListeners();
  }

  void _onSpeechResult(dynamic result) async {
    _recognizedText = result.recognizedWords ?? '';
    notifyListeners();

    if (result.finalResult && _recognizedText.isNotEmpty) {
      print('LiveAICallService: Final result: $_recognizedText');

      await _stopListening();
      _updateState(LiveAICallState.processing, 'AI is thinking...');

      // Send to backend
      await _sendSpeechToBackend(_recognizedText);
    }
  }

  Future<void> _sendSpeechToBackend(String text) async {
    if (_sessionId == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai-sathi/live-call/speech'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'session_id': _sessionId,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _aiResponse = data['text'] ?? '';
        _totalInteractions =
            data['interaction_count'] ?? _totalInteractions + 1;

        // Add to conversation history
        _conversationHistory.add({
          'role': 'user',
          'content': text,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        _conversationHistory.add({
          'role': 'assistant',
          'content': _aiResponse,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Play audio if available
        if (data['audio_url'] != null) {
          _updateState(LiveAICallState.playingResponse, 'AI is speaking...');
          await _playAudioResponse(data['audio_url']);
        } else {
          // No audio, show text and resume listening
          _updateState(LiveAICallState.ready, 'Ask another question...');
          await _startListening();
        }

        notifyListeners();
      } else {
        throw Exception('Failed to send speech: ${response.statusCode}');
      }
    } catch (e) {
      print('LiveAICallService: Error sending speech: $e');
      _updateState(LiveAICallState.error, 'Error: $e');

      // Try to recover
      Future.delayed(const Duration(seconds: 2), () {
        if (_isConnected) {
          _updateState(LiveAICallState.ready, 'Please try again...');
          _startListening();
        }
      });
    }
  }

  Future<void> _playAudioResponse(String audioUrl) async {
    try {
      _isPlayingResponse = true;
      notifyListeners();

      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('LiveAICallService: Error playing audio: $e');
      _isPlayingResponse = false;
      _scheduleListeningResume();
    }
  }

  void _scheduleListeningResume() {
    if (_isResumeScheduled) return;

    _isResumeScheduled = true;
    _isPlayingResponse = false;
    _updateState(LiveAICallState.ready, 'AI finished speaking...');

    _resumeListeningTimer?.cancel();
    _resumeListeningTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isConnected &&
          !_isPlayingResponse &&
          !_isListening &&
          _state != LiveAICallState.processing) {
        _isResumeScheduled = false;
        _updateState(LiveAICallState.listening, 'Listening...');
        _startListening();
      } else {
        _isResumeScheduled = false;
      }
    });
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
    }
    _voiceActivityTimer?.cancel();
  }

  Future<void> _resetAudioPlayerForListening() async {
    try {
      if (_audioPlayerInitialized) {
        await _audioPlayer.stop();
      }
      _isPlayingResponse = false;
    } catch (e) {
      print('LiveAICallService: Error resetting audio player: $e');
    }
  }
}
