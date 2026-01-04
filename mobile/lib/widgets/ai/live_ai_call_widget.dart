import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../services/live_ai_call_service.dart';
import '../../config/theme.dart';

/// Live AI Call Widget - Healthcare voice consultation UI
class LiveAICallWidget extends StatefulWidget {
  final LiveAICallConfig config;
  final VoidCallback? onClose;
  final bool showAsBottomSheet;
  final String title;
  final String? continueSessionId;

  const LiveAICallWidget({
    super.key,
    required this.config,
    this.onClose,
    this.showAsBottomSheet = true,
    this.title = 'AI Health Consultation',
    this.continueSessionId,
  });

  @override
  State<LiveAICallWidget> createState() => _LiveAICallWidgetState();
}

class _LiveAICallWidgetState extends State<LiveAICallWidget>
    with TickerProviderStateMixin {
  late LiveAICallService _aiService;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late LiveAICallConfig _currentConfig;

  @override
  void initState() {
    super.initState();
    _aiService = LiveAICallService.instance;
    _currentConfig = widget.config;
    _setupAnimations();
    _initializeService();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeService() async {
    final initialized = await _aiService.initialize();
    if (!initialized && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to initialize AI service'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAsBottomSheet) {
      return _buildBottomSheet();
    } else {
      return _buildFullScreen();
    }
  }

  Widget _buildBottomSheet() {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85;

    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHandle(),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildContent(),
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildFullScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildContent(),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (widget.onClose != null)
            IconButton(
              onPressed: () {
                if (_aiService.state != LiveAICallState.idle) {
                  _aiService.endCall();
                }
                widget.onClose?.call();
              },
              icon: Icon(
                widget.showAsBottomSheet ? Icons.close : Icons.arrow_back,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AnimatedBuilder(
                  animation: _aiService,
                  builder: (context, child) {
                    return Text(
                      _aiService.state != LiveAICallState.idle
                          ? _formatDuration(_aiService.callDuration)
                          : 'Voice Health Assistant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _aiService,
            builder: (context, child) {
              if (_aiService.isConnected) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMedicalDisclaimer(),
          const SizedBox(height: 20),
          _buildAIAvatar(),
          const SizedBox(height: 24),
          _buildStatusText(),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _aiService,
            builder: (context, child) {
              if (_aiService.isConnected) {
                return _buildSpeechVisualization();
              } else {
                return _buildLanguageSelection();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildRecognizedText(),
          _buildAIResponse(),
          _buildSessionProgress(),
        ],
      ),
    );
  }

  Widget _buildMedicalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is AI health guidance, not medical diagnosis. Please consult a doctor for proper medical advice.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAvatar() {
    return AnimatedBuilder(
      animation: _aiService,
      builder: (context, child) {
        if (_aiService.isConnected) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }

        if (_aiService.isSpeaking || _aiService.isPlayingResponse) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
          _waveController.reset();
        }

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                if (_aiService.isConnected &&
                    !_aiService.isListening &&
                    !_aiService.isSpeaking &&
                    _aiService.state != LiveAICallState.processing &&
                    !_aiService.isCalibrating) {
                  _aiService.forceResumeListening();
                } else if (_aiService.isPlayingResponse) {
                  _aiService.stopAIAndResumeListen();
                }
              },
              child: Transform.scale(
                scale: _aiService.isConnected ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _aiService.isPlayingResponse
                          ? Colors.green
                          : _aiService.state == LiveAICallState.processing
                              ? Colors.orange
                              : _aiService.isSpeaking
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _aiService.isPlayingResponse
                              ? Icons.volume_up
                              : _aiService.state == LiveAICallState.processing
                                  ? Icons.psychology
                                  : Icons.medical_services,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      if (_aiService.isPlayingResponse || _aiService.isSpeaking)
                        AnimatedBuilder(
                          animation: _waveAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (_aiService.isPlayingResponse
                                          ? Colors.green
                                          : AppColors.primary)
                                      .withOpacity(
                                          0.5 * (1 - _waveAnimation.value)),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusText() {
    return AnimatedBuilder(
      animation: _aiService,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              _aiService.isCalibrating
                  ? 'Calibrating microphone...'
                  : _aiService.statusMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_aiService.state == LiveAICallState.processing)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Doctor is thinking...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            if (_aiService.isCalibrating)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Please stay quiet for calibration',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            if (_aiService.isConnected &&
                !_aiService.isCalibrating &&
                _aiService.state != LiveAICallState.processing)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _aiService.isPlayingResponse
                        ? Icons.volume_up
                        : _aiService.isSpeaking
                            ? Icons.mic
                            : Icons.mic_none,
                    size: 16,
                    color: _aiService.isPlayingResponse
                        ? Colors.green
                        : _aiService.isSpeaking
                            ? AppColors.primary
                            : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _aiService.isPlayingResponse
                        ? 'AI speaking (tap to interrupt)'
                        : _aiService.isSpeaking
                            ? 'Listening to your symptoms...'
                            : 'Voice detection active',
                    style: TextStyle(
                      fontSize: 12,
                      color: _aiService.isPlayingResponse
                          ? Colors.green
                          : _aiService.isSpeaking
                              ? AppColors.primary
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            if (_aiService.isConnected &&
                !_aiService.isListening &&
                !_aiService.isPlayingResponse &&
                _aiService.state != LiveAICallState.processing &&
                !_aiService.isCalibrating)
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: _aiService.forceResumeListening,
                  icon: const Icon(Icons.mic, size: 16),
                  label: const Text('Tap to resume listening',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLanguageGrid(),
        ],
      ),
    );
  }

  Widget _buildLanguageGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityLanguages = [
      AICallLanguage.english,
      AICallLanguage.nepali,
      AICallLanguage.hindi,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: priorityLanguages.map((language) {
        final isSelected = _currentConfig.language == language;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentConfig = _currentConfig.copyWith(language: language);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : isDark
                      ? Colors.grey.shade700
                      : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(language.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  language.displayName.split(' ').first,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? Colors.white
                            : Colors.grey.shade700,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check, size: 14, color: AppColors.primary),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpeechVisualization() {
    return AnimatedBuilder(
      animation: _aiService,
      builder: (context, child) {
        return SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final clampedSoundLevel = math.max(0.0, _aiService.soundLevel);
              final multiplier = index % 2 == 0 ? 1.0 : 0.7;

              final calculatedHeight = _aiService.isSpeaking
                  ? 8.0 + (clampedSoundLevel * 40.0 * multiplier)
                  : 8.0;

              final finalHeight =
                  math.max(8.0, math.min(50.0, calculatedHeight));

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: finalHeight,
                decoration: BoxDecoration(
                  color: _aiService.isSpeaking
                      ? AppColors.primary.withOpacity(0.8)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildRecognizedText() {
    return AnimatedBuilder(
      animation: _aiService,
      builder: (context, child) {
        if (_aiService.recognizedText.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'You said:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _aiService.recognizedText,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIResponse() {
    return AnimatedBuilder(
      animation: _aiService,
      builder: (context, child) {
        if (_aiService.aiResponse.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_services,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Doctor:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  if (_aiService.isPlayingResponse)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up,
                            size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Speaking...',
                          style: TextStyle(
                              fontSize: 10, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _aiService.aiResponse,
                style: const TextStyle(fontSize: 14),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionProgress() {
    return AnimatedBuilder(
      animation: _aiService,
      builder: (context, child) {
        if (!_aiService.isConnected || _aiService.totalInteractions == 0) {
          return const SizedBox.shrink();
        }

        final interactionProgress =
            math.min(1.0, _aiService.totalInteractions / 10.0);
        final progressPercent = (interactionProgress * 100).round();

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Consultation Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: interactionProgress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$progressPercent%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Interactions: ${_aiService.totalInteractions}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _aiService,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_aiService.isConnected) ...[
                _buildControlButton(
                  icon: _aiService.isListening ? Icons.mic : Icons.mic_off,
                  color:
                      _aiService.isListening ? AppColors.primary : Colors.red,
                  onPressed: _aiService.toggleMute,
                  label: _aiService.isListening ? 'Mute' : 'Unmute',
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onPressed: () async {
                    await _aiService.endCall();
                    widget.onClose?.call();
                  },
                  label: 'End',
                  size: 60,
                ),
                _buildControlButton(
                  icon: Icons.volume_up,
                  color: Colors.green,
                  onPressed: () {},
                  label: 'Speaker',
                ),
              ] else ...[
                Expanded(child: _buildStartCallButton()),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
    double size = 50,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(size / 2),
              onTap: onPressed,
              child: Center(
                child: Icon(icon, color: color, size: size * 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStartCallButton() {
    return AnimatedBuilder(
      animation: _aiService,
      builder: (context, child) {
        final isConnecting = _aiService.state == LiveAICallState.connecting;

        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: isConnecting
                  ? null
                  : () => _aiService.startCall(_currentConfig,
                      continueSessionId: widget.continueSessionId),
              child: Center(
                child: isConnecting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Connecting...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Start Health Consultation',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentConfig.language.flag,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentConfig.language.displayName
                                    .split(' ')
                                    .first,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Helper function to show Live AI Call as bottom sheet
Future<void> showLiveAICallBottomSheet({
  required BuildContext context,
  required LiveAICallConfig config,
  String title = 'AI Health Consultation',
  String? continueSessionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return LiveAICallWidget(
        config: config,
        title: title,
        continueSessionId: continueSessionId,
        onClose: () => Navigator.of(context).pop(),
      );
    },
  );
}
