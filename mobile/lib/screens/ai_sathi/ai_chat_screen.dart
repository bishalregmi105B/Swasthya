import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';
import '../../widgets/ai/ai_message_renderer.dart';
import '../../providers/health_mode_provider.dart';

class AIChatScreen extends StatefulWidget {
  final String category;

  const AIChatScreen({super.key, required this.category});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  List<String> _suggestions = [];
  bool _loadingSuggestions = false;

  // Language selection
  String _selectedLanguage = 'en';
  static const Map<String, String> _languages = {
    'en': 'English',
    'ne': 'नेपाली',
    'hi': 'हिन्दी',
  };

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _loadingSuggestions = true);
    try {
      final history = _messages
          .map((m) => {
                'text': m.text,
                'isUser': m.isUser,
              })
          .toList();
      final suggestions = await apiService.getSuggestedQuestions(
        widget.category,
        history: history.isEmpty ? null : history,
        language: _selectedLanguage,
      );
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSuggestions = false);
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
      // Get health mode from provider
      final healthMode = context.read<HealthModeProvider>().modeString;
      final response = await apiService.aiChat(text, widget.category,
          language: _selectedLanguage, healthMode: healthMode);
      setState(() {
        _messages.add(_ChatMessage(
          response['response'] ??
              'I apologize, but I could not process your request.',
          false,
          DateTime.now(),
        ));
        _isLoading = false;
      });
      // Refresh suggestions after AI response
      _loadSuggestions();
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

  String _getCategoryTitle() {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.category) {
      case 'physician':
        return l10n.generalPhysician;
      case 'psychiatrist':
        return l10n.mentalHealth;
      case 'dermatologist':
        return l10n.dermatologist;
      case 'pediatrician':
        return l10n.pediatrician;
      case 'nutritionist':
        return l10n.nutritionist;
      case 'cardiologist':
        return l10n.cardiologist;
      default:
        return l10n.aiSathi;
    }
  }

  /// Start voice call with the current specialist
  void _startVoiceCall() {
    showLiveAICallBottomSheet(
      context: context,
      config: LiveAICallConfig(
        specialist: widget.category,
        patientContext: _messages.isNotEmpty
            ? 'Previous conversation context: ${_messages.take(3).map((m) => m.text).join(". ")}'
            : null,
      ),
      title: '${_getCategoryTitle()} - Voice Call',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_getCategoryTitle(), style: const TextStyle(fontSize: 16)),
            Text(
              'AI Assistant',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          // Voice call button
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.phone, color: AppColors.primary),
              tooltip: 'Voice Call',
              onPressed: _startVoiceCall,
            ),
          ),
          // Language selector
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _languages[_selectedLanguage] ?? 'English',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ),
            tooltip: 'Select Language',
            onSelected: (String language) {
              setState(() => _selectedLanguage = language);
            },
            itemBuilder: (context) => _languages.entries.map((entry) {
              return PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    if (_selectedLanguage == entry.key)
                      const Icon(Icons.check,
                          size: 18, color: AppColors.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
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
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 64,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.askAiSathi,
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // AI Suggested Questions
          if (_suggestions.isNotEmpty || _loadingSuggestions)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _loadingSuggestions
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: const Icon(Icons.auto_awesome,
                                size: 16, color: AppColors.primary),
                            label: Text(
                              _suggestions[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            side: BorderSide.none,
                            onPressed: () {
                              _messageController.text = _suggestions[index];
                              _sendMessage();
                            },
                          ),
                        );
                      },
                    ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
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
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: l10n.typeSymptomsHint,
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
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    // Use AIMessageRenderer for rich rendering of AI responses with tags
    return AIMessageRenderer(
      message: message.text,
      isUser: message.isUser,
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
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage(this.text, this.isUser, this.timestamp);
}
