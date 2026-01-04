import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

/// Model for AI Conversation
class AIConversation {
  final int id;
  final String sessionId;
  final String conversationType; // 'chat' or 'voice_call'
  final String specialistType;
  final String languageCode;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int totalMessages;
  final String? summary;
  final String? title;
  final List<AIMessage>? messages;

  AIConversation({
    required this.id,
    required this.sessionId,
    required this.conversationType,
    required this.specialistType,
    this.languageCode = 'en-US',
    this.startedAt,
    this.endedAt,
    this.totalMessages = 0,
    this.summary,
    this.title,
    this.messages,
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: json['id'] ?? 0,
      sessionId: json['session_id'] ?? '',
      conversationType: json['conversation_type'] ?? 'chat',
      specialistType: json['specialist_type'] ?? 'physician',
      languageCode: json['language_code'] ?? 'en-US',
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      endedAt:
          json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      totalMessages: json['total_messages'] ?? 0,
      summary: json['summary'],
      title: json['title'],
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((m) => AIMessage.fromJson(m))
              .toList()
          : null,
    );
  }

  String get displayTitle =>
      title ?? '${_capitalizeFirst(specialistType)} Consultation';

  bool get isVoiceCall => conversationType == 'voice_call';
  bool get isChat => conversationType == 'chat';

  String get formattedDate {
    if (startedAt == null) return 'Unknown';
    final now = DateTime.now();
    final diff = now.difference(startedAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${startedAt!.day}/${startedAt!.month}/${startedAt!.year}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }
}

/// Model for AI Message
class AIMessage {
  final int id;
  final int conversationId;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final String? audioUrl;
  final DateTime? createdAt;

  AIMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.audioUrl,
    this.createdAt,
  });

  factory AIMessage.fromJson(Map<String, dynamic> json) {
    return AIMessage(
      id: json['id'] ?? 0,
      conversationId: json['conversation_id'] ?? 0,
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      audioUrl: json['audio_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// Model for AI usage stats
class AIStats {
  final int totalConversations;
  final int totalMessages;
  final int chatConversations;
  final int voiceConversations;
  final Map<String, int> bySpecialist;

  AIStats({
    required this.totalConversations,
    required this.totalMessages,
    required this.chatConversations,
    required this.voiceConversations,
    required this.bySpecialist,
  });

  factory AIStats.fromJson(Map<String, dynamic> json) {
    return AIStats(
      totalConversations: json['total_conversations'] ?? 0,
      totalMessages: json['total_messages'] ?? 0,
      chatConversations: json['chat_conversations'] ?? 0,
      voiceConversations: json['voice_conversations'] ?? 0,
      bySpecialist: Map<String, int>.from(json['by_specialist'] ?? {}),
    );
  }
}

/// Service for AI Chat History
class AIHistoryService {
  static const String baseUrl = 'https://aacademyapi.ashlya.com/api';
  final Box _settingsBox = Hive.box('settings');

  String? get _accessToken => _settingsBox.get('access_token');

  Map<String, String> get _headers {
    final token = _accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all AI conversations with optional filters
  Future<List<AIConversation>> getConversations({
    String? type, // 'chat' or 'voice_call'
    String? specialist,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (type != null) queryParams['type'] = type;
      if (specialist != null) queryParams['specialist'] = specialist;

      final response = await http.get(
        Uri.parse('$baseUrl/ai-history/conversations')
            .replace(queryParameters: queryParams),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data['conversations'] != null) {
          return (data['conversations'] as List)
              .map((c) => AIConversation.fromJson(c))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching AI conversations: $e');
      return [];
    }
  }

  /// Get a single conversation with messages
  Future<AIConversation?> getConversation(int conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai-history/conversations/$conversationId'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data['conversation'] != null) {
          return AIConversation.fromJson(data['conversation']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
      return null;
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(int conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/ai-history/conversations/$conversationId'),
        headers: _headers,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      return false;
    }
  }

  /// Delete all conversations
  Future<bool> clearAllConversations() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/ai-history/conversations'),
        headers: _headers,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error clearing conversations: $e');
      return false;
    }
  }

  /// Get usage statistics
  Future<AIStats?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai-history/stats'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AIStats.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching AI stats: $e');
      return null;
    }
  }
}
