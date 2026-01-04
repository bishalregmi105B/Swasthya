import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../services/ai_history_service.dart';

class AIHistoryScreen extends StatefulWidget {
  const AIHistoryScreen({super.key});

  @override
  State<AIHistoryScreen> createState() => _AIHistoryScreenState();
}

class _AIHistoryScreenState extends State<AIHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AIHistoryService _historyService = AIHistoryService();

  List<AIConversation> _conversations = [];
  AIStats? _stats;
  bool _isLoading = true;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentFilter = 'all';
            break;
          case 1:
            _currentFilter = 'chat';
            break;
          case 2:
            _currentFilter = 'voice_call';
            break;
        }
      });
      _loadConversations();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([_loadConversations(), _loadStats()]);
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final conversations = await _historyService.getConversations(
      type: _currentFilter == 'all' ? null : _currentFilter,
    );
    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
  }

  Future<void> _loadStats() async {
    final stats = await _historyService.getStats();
    setState(() => _stats = stats);
  }

  Future<void> _deleteConversation(AIConversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConversation),
        content:
            const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _historyService.deleteConversation(conversation.id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conversation deleted')));
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiChatHistory),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.textChats),
            Tab(text: l10n.voiceCalls)
          ],
        ),
        actions: [
          if (_conversations.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'clear_all') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.clearAllHistory),
                      content: const Text(
                          'This will delete all AI conversations. Cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await _historyService.clearAllConversations();
                    _loadData();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All')
                  ]),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (_stats != null) _buildStatsCard(primaryColor),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) =>
                              _buildConversationCard(
                                  _conversations[index], primaryColor),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Chats', _stats!.totalConversations.toString()),
          _buildStatItem('Messages', _stats!.totalMessages.toString()),
          _buildStatItem('Text', _stats!.chatConversations.toString()),
          _buildStatItem('Voice', _stats!.voiceConversations.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style:
                TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No conversations yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Start chatting with AI Sathi',
              style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/chats'),
            icon: const Icon(Icons.smart_toy),
            label: const Text('Chat with AI Sathi'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(
      AIConversation conversation, Color primaryColor) {
    final isVoice = conversation.isVoiceCall;
    final iconColor = isVoice ? Colors.purple : primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showConversationDetail(conversation, primaryColor),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    Icon(isVoice ? Icons.call : Icons.chat, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conversation.displayTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(_getSpecialistIcon(conversation.specialistType),
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(_formatSpecialist(conversation.specialistType),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(width: 12),
                      Icon(Icons.message, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('${conversation.totalMessages}',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(conversation.formattedDate,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(isVoice ? 'Voice' : 'Chat',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: iconColor)),
                  ),
                ],
              ),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteConversation(conversation)),
            ],
          ),
        ),
      ),
    );
  }

  void _showConversationDetail(
      AIConversation conversation, Color primaryColor) async {
    final fullConversation =
        await _historyService.getConversation(conversation.id);
    if (fullConversation == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(fullConversation.isVoiceCall ? Icons.call : Icons.chat,
                      color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(fullConversation.displayTitle,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ]),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: fullConversation.messages?.length ?? 0,
                  itemBuilder: (context, index) => _buildMessageBubble(
                      fullConversation.messages![index], primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message, Color primaryColor) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.content,
                style: TextStyle(
                    color: isUser ? Colors.white : null, fontSize: 14)),
            if (message.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                  '${message.createdAt!.hour}:${message.createdAt!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500])),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getSpecialistIcon(String specialist) {
    switch (specialist.toLowerCase()) {
      case 'physician':
        return Icons.medical_services;
      case 'psychiatrist':
        return Icons.psychology;
      case 'dermatologist':
        return Icons.face;
      case 'pediatrician':
        return Icons.child_care;
      case 'nutritionist':
        return Icons.restaurant;
      case 'cardiologist':
        return Icons.favorite;
      default:
        return Icons.person;
    }
  }

  String _formatSpecialist(String specialist) => specialist
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
