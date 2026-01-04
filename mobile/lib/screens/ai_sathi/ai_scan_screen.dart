import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';
import '../../widgets/ai/markdown_text.dart';
import '../../providers/locale_provider.dart';

/// Analyzer type configuration
class AnalyzerConfig {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String specialist;
  final String uploadHint;

  const AnalyzerConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.specialist,
    required this.uploadHint,
  });
}

/// AI Image Scan Screen - Upload health images for AI analysis
class AIScanScreen extends StatefulWidget {
  final String analyzerType;

  const AIScanScreen({super.key, this.analyzerType = 'general'});

  @override
  State<AIScanScreen> createState() => _AIScanScreenState();
}

class _AIScanScreenState extends State<AIScanScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  File? _selectedImage;
  String? _imageAnalysis;
  final List<_ChatMessage> _messages = [];
  bool _isAnalyzing = false;
  bool _isLoading = false;
  String _selectedLanguage = 'en';

  // Analyzer configurations
  static const Map<String, AnalyzerConfig> _analyzerConfigs = {
    'lab_report': AnalyzerConfig(
      id: 'lab_report',
      title: 'Lab Report Analyzer',
      subtitle: 'CBC, Blood Tests, Lipid Panel',
      icon: Icons.biotech,
      color: Colors.blue,
      specialist: 'pathologist',
      uploadHint: 'Upload your lab report (CBC, blood test, lipid panel, etc.)',
    ),
    'prescription': AnalyzerConfig(
      id: 'prescription',
      title: 'Prescription Analyzer',
      subtitle: 'Medicine & Dosage',
      icon: Icons.medication,
      color: Colors.purple,
      specialist: 'pharmacist',
      uploadHint: 'Upload your prescription or medicine label',
    ),
    'skin': AnalyzerConfig(
      id: 'skin',
      title: 'Skin Condition Analyzer',
      subtitle: 'Dermatology',
      icon: Icons.face_retouching_natural,
      color: Colors.orange,
      specialist: 'dermatologist',
      uploadHint: 'Upload a clear photo of the skin condition',
    ),
    'xray': AnalyzerConfig(
      id: 'xray',
      title: 'X-Ray / Scan Analyzer',
      subtitle: 'X-ray, CT, MRI',
      icon: Icons.medical_services,
      color: Colors.teal,
      specialist: 'radiologist',
      uploadHint: 'Upload your X-ray, CT scan, or MRI image',
    ),
    'ecg': AnalyzerConfig(
      id: 'ecg',
      title: 'ECG Analyzer',
      subtitle: 'Heart Monitoring',
      icon: Icons.monitor_heart,
      color: Colors.red,
      specialist: 'cardiologist',
      uploadHint: 'Upload your ECG/EKG report or strip',
    ),
    'general': AnalyzerConfig(
      id: 'general',
      title: 'General Health Analyzer',
      subtitle: 'Any Health Document',
      icon: Icons.health_and_safety,
      color: Colors.green,
      specialist: 'physician',
      uploadHint: 'Upload any health-related document or image',
    ),
  };

  AnalyzerConfig get _config =>
      _analyzerConfigs[widget.analyzerType] ?? _analyzerConfigs['general']!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localeProvider = context.read<LocaleProvider>();
      setState(() {
        _selectedLanguage = localeProvider.isEnglish ? 'en' : 'ne';
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageAnalysis = null;
          _messages.clear();
        });

        // Auto-analyze after selection
        await _analyzeImage();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // Send image to backend for analysis with type and language
      final result = await apiService.analyzeHealthImage(
        _selectedImage!,
        analysisType: widget.analyzerType,
        language: _selectedLanguage,
      );

      setState(() {
        _imageAnalysis = result['analysis'] ?? 'Unable to analyze image';
        _messages.add(_ChatMessage(
          _imageAnalysis!,
          false,
          DateTime.now(),
          isAnalysis: true,
        ));
        _isAnalyzing = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _imageAnalysis = 'Failed to analyze image. Please try again.';
        _isAnalyzing = false;
      });
      _showError('Analysis failed: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text, true, DateTime.now()));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Include image context in the chat
      final imageContext = _imageAnalysis != null
          ? 'Previous image analysis: $_imageAnalysis. '
          : '';

      final response = await apiService.aiChat(
        '$imageContext User follow-up question: $text',
        _config.specialist,
      );

      setState(() {
        _messages.add(_ChatMessage(
          response['response'] ?? 'I could not process your request.',
          false,
          DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          'Sorry, there was an error. Please try again.',
          false,
          DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _startVoiceCall() {
    showLiveAICallBottomSheet(
      context: context,
      config: LiveAICallConfig(
        specialist: _config.specialist,
        patientContext: _imageAnalysis != null
            ? 'Image analysis result (${_config.title}): $_imageAnalysis'
            : 'User wants to discuss a ${_config.title.toLowerCase()} image',
        language: _selectedLanguage == 'ne'
            ? AICallLanguage.nepali
            : AICallLanguage.english,
      ),
      title: 'AI ${_config.title} Call',
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: _selectedLanguage == 'en'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = 'en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇳🇵', style: TextStyle(fontSize: 24)),
              title: const Text('नेपाली (Nepali)'),
              trailing: _selectedLanguage == 'ne'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = 'ne');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_config.icon, color: _config.color, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_config.title, style: const TextStyle(fontSize: 15)),
                  Text(
                    _config.subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language selector
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Text(
                _selectedLanguage == 'en' ? '🇺🇸' : '🇳🇵',
                style: const TextStyle(fontSize: 20),
              ),
              tooltip: 'Change Language',
              onPressed: _showLanguageSelector,
            ),
          ),
          // AI Call button
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _config.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(Icons.phone, color: _config.color),
                tooltip: l10n.voiceCall,
                onPressed: _startVoiceCall,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _getItemCount(),
              itemBuilder: (context, index) {
                return _buildScrollableItem(context, l10n, index);
              },
            ),
          ),
          // Input area pinned at bottom
          if (_selectedImage != null) _buildInputArea(l10n),
        ],
      ),
    );
  }

  /// Calculate total items for ListView: disclaimer + image/upload + messages + loading
  int _getItemCount() {
    int count = 2; // Disclaimer + Image/Upload section
    count += _messages.length;
    if (_isLoading || _isAnalyzing) count += 1; // Loading indicator
    return count;
  }

  /// Build individual scrollable items
  Widget _buildScrollableItem(
      BuildContext context, AppLocalizations l10n, int index) {
    // Item 0: Disclaimer
    if (index == 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.aiDisclaimer,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    // Item 1: Image section or upload prompt
    if (index == 1) {
      if (_selectedImage == null) {
        return _buildUploadSection(l10n);
      } else {
        return _buildImagePreview(l10n);
      }
    }

    // Messages (index 2+)
    final messageIndex = index - 2;
    if (messageIndex < _messages.length) {
      return _buildMessageBubble(_messages[messageIndex], l10n);
    }

    // Loading indicator
    if (_isLoading || _isAnalyzing) {
      return _buildTypingIndicator();
    }

    return const SizedBox.shrink();
  }

  Widget _buildUploadSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _config.color.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _config.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _config.icon,
              size: 40,
              color: _config.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.uploadHealthImage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _config.uploadHint,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n.camera),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _config.color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.gallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _config.color,
                  side: BorderSide(color: _config.color),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _selectedImage!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 20),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _imageAnalysis = null;
                        _messages.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _config.color),
                      const SizedBox(height: 12),
                      Text(
                        l10n.analyzingImage,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _config.icon,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.uploadImageToStart,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, AppLocalizations l10n) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? _config.color
              : message.isAnalysis
                  ? _config.color.withOpacity(0.1)
                  : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
          border: message.isAnalysis
              ? Border.all(color: _config.color.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isAnalysis) ...[
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: _config.color),
                  const SizedBox(width: 6),
                  Text(
                    l10n.aiAnalysis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _config.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Use MarkdownText for AI responses, plain Text for user messages
            message.isUser
                ? Text(
                    message.text,
                    style: const TextStyle(color: Colors.white),
                  )
                : MarkdownText(
                    data: message.text,
                    textStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              3,
              (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _config.color.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  )),
        ),
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(12, 12, 80, 12), // Extra padding for FAB
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: l10n.askAboutImage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _config.color,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isAnalysis;

  _ChatMessage(this.text, this.isUser, this.timestamp,
      {this.isAnalysis = false});
}
