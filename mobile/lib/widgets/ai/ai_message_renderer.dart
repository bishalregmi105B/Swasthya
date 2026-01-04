import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import 'markdown_text.dart';

/// Tag types that can be parsed from AI responses
enum AITagType {
  doctor,
  hospital,
  medicine,
  pharmacy,
  bloodBank,
  emergency,
  bookAppointment
}

/// Parsed AI tag with type and properties
class AITag {
  final AITagType type;
  final Map<String, String> properties;
  final int startIndex;
  final int endIndex;

  AITag({
    required this.type,
    required this.properties,
    required this.startIndex,
    required this.endIndex,
  });
}

/// Widget that renders AI responses with embedded actionable tags
class AIMessageRenderer extends StatelessWidget {
  final String message;
  final bool isUser;

  const AIMessageRenderer({
    super.key,
    required this.message,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      // User messages are plain text
      return _buildUserBubble(context, message);
    }

    // Parse and render AI message with tags
    final segments = _parseMessage(message);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((segment) {
          if (segment is String) {
            return _buildTextSegment(context, segment);
          } else if (segment is AITag) {
            return _buildTagWidget(context, segment);
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTextSegment(BuildContext context, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check for <think> tags (DeepSeek R1 reasoning)
    final thinkPattern =
        RegExp(r'<think>([\s\S]*?)</think>', caseSensitive: false);
    final thinkMatch = thinkPattern.firstMatch(text);

    if (thinkMatch != null) {
      final thinkContent = thinkMatch.group(1)?.trim() ?? '';
      final remainingText = text.replaceAll(thinkPattern, '').trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible think section
          if (thinkContent.isNotEmpty)
            _ThinkCollapsible(content: thinkContent, isDark: isDark),
          // Remaining text
          if (remainingText.isNotEmpty)
            _buildTextSegment(context, remainingText),
        ],
      );
    }

    // Check for disclaimer (⚠️) - split main content from disclaimer
    if (text.contains('⚠️')) {
      // Find where disclaimer starts
      final disclaimerStart = text.indexOf('⚠️');
      final mainContent = text.substring(0, disclaimerStart).trim();
      final disclaimerContent =
          text.substring(disclaimerStart).replaceAll('⚠️', '').trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content as markdown
          if (mainContent.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8, right: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: MarkdownText(
                data: mainContent,
                shrinkWrap: true,
              ),
            ),
          // Disclaimer as alert card
          if (disclaimerContent.isNotEmpty)
            MedicalAlertCard(
              title: 'Disclaimer',
              content: disclaimerContent,
              type: MedicalAlertType.warning,
            ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      // Use MarkdownText for rich markdown rendering
      child: MarkdownText(
        data: text,
        shrinkWrap: true,
      ),
    );
  }

  // NOTE: Custom markdown methods removed - now using MarkdownText widget from markdown_text.dart
  // which provides full markdown support with healthcare styling including:
  // - Headers, bold, italic, code blocks
  // - Tables, blockquotes, links
  // - Proper theme integration

  Widget _buildTagWidget(BuildContext context, AITag tag) {
    switch (tag.type) {
      case AITagType.doctor:
        return _buildDoctorCard(context, tag);
      case AITagType.hospital:
        return _buildHospitalCard(context, tag);
      case AITagType.medicine:
        return _buildMedicineChip(context, tag);
      case AITagType.pharmacy:
        return _buildPharmacyCard(context, tag);
      case AITagType.bloodBank:
        return _buildBloodBankCard(context, tag);
      case AITagType.emergency:
        return _buildEmergencyCard(context, tag);
      case AITagType.bookAppointment:
        return _buildBookButton(context, tag);
    }
  }

  Widget _buildDoctorCard(BuildContext context, AITag tag) {
    final id = tag.properties['id'];
    final name = tag.properties['name'] ?? 'Doctor';
    final specialty = tag.properties['specialty'] ?? '';

    return GestureDetector(
      onTap: () {
        if (id != null) {
          context.push('/doctors/$id');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (specialty.isNotEmpty)
                    Text(
                      specialty,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, AITag tag) {
    final id = tag.properties['id'];
    final name = tag.properties['name'] ?? 'Hospital';
    final type = tag.properties['type'] ?? 'hospital';

    return GestureDetector(
      onTap: () {
        if (id != null) {
          context.push('/hospital/$id'); // Note: singular, not /hospitals
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.withOpacity(0.2),
              child: const Icon(Icons.local_hospital, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineChip(BuildContext context, AITag tag) {
    final name = tag.properties['name'] ?? 'Medicine';
    final type = tag.properties['type'] ?? 'OTC';
    final isRx = type.toLowerCase().contains('rx') ||
        type.toLowerCase().contains('prescription');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Chip(
        avatar: Icon(
          isRx ? Icons.medication : Icons.medical_services,
          size: 18,
          color: isRx ? Colors.orange : Colors.green,
        ),
        label: Text(name),
        backgroundColor: (isRx ? Colors.orange : Colors.green).withOpacity(0.1),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, AITag tag) {
    final name = tag.properties['name'] ?? 'Pharmacy';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_pharmacy, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, color: Colors.purple),
        ],
      ),
    );
  }

  Widget _buildBloodBankCard(BuildContext context, AITag tag) {
    final name = tag.properties['name'] ?? 'Blood Bank';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.bloodtype, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, AITag tag) {
    final name = tag.properties['name'] ?? 'Emergency';
    final phone = tag.properties['phone'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                if (phone.isNotEmpty)
                  Text(phone,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.call, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context, AITag tag) {
    final doctorId = tag.properties['doctor_id'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (doctorId != null) {
            context.push('/doctors/$doctorId');
          }
        },
        icon: const Icon(Icons.calendar_today),
        label: const Text('Book Appointment'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// Parse message into segments of text and tags
  List<dynamic> _parseMessage(String message) {
    final segments = <dynamic>[];
    final tagPattern = RegExp(
      r'\[(Doctor|Hospital|Medicine|Pharmacy|BloodBank|Emergency|BookAppointment):\s*([^\]]+)\]',
      caseSensitive: false,
    );

    int lastEnd = 0;

    for (final match in tagPattern.allMatches(message)) {
      // Add text before tag
      if (match.start > lastEnd) {
        final text = message.substring(lastEnd, match.start).trim();
        if (text.isNotEmpty) segments.add(text);
      }

      // Parse tag
      final typeStr = match.group(1)!.toLowerCase();
      final propsStr = match.group(2)!;

      final type = _parseTagType(typeStr);
      final props = _parseProperties(propsStr);

      if (type != null) {
        segments.add(AITag(
          type: type,
          properties: props,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < message.length) {
      final text = message.substring(lastEnd).trim();
      if (text.isNotEmpty) segments.add(text);
    }

    return segments;
  }

  AITagType? _parseTagType(String type) {
    switch (type.toLowerCase()) {
      case 'doctor':
        return AITagType.doctor;
      case 'hospital':
        return AITagType.hospital;
      case 'medicine':
        return AITagType.medicine;
      case 'pharmacy':
        return AITagType.pharmacy;
      case 'bloodbank':
        return AITagType.bloodBank;
      case 'emergency':
        return AITagType.emergency;
      case 'bookappointment':
        return AITagType.bookAppointment;
      default:
        return null;
    }
  }

  Map<String, String> _parseProperties(String propsStr) {
    final props = <String, String>{};

    // Parse key=value or key="value" pairs
    final pattern = RegExp(r'(\w+)\s*=\s*"?([^",\]]+)"?');

    for (final match in pattern.allMatches(propsStr)) {
      final key = match.group(1)!;
      final value = match.group(2)!.trim();
      props[key] = value;
    }

    return props;
  }
}

/// Collapsible widget for <think> reasoning tags from DeepSeek R1
class _ThinkCollapsible extends StatefulWidget {
  final String content;
  final bool isDark;

  const _ThinkCollapsible({
    required this.content,
    required this.isDark,
  });

  @override
  State<_ThinkCollapsible> createState() => _ThinkCollapsibleState();
}

class _ThinkCollapsibleState extends State<_ThinkCollapsible> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 48),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.purple.shade900.withOpacity(0.3)
            : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? Colors.purple.shade700.withOpacity(0.5)
              : Colors.purple.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    size: 18,
                    color: widget.isDark
                        ? Colors.purple.shade200
                        : Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Reasoning',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: widget.isDark
                          ? Colors.purple.shade200
                          : Colors.purple.shade700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: widget.isDark
                        ? Colors.purple.shade200
                        : Colors.purple.shade700,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                widget.content,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
