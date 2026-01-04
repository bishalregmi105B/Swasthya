import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// Markdown Text Widget - Renders markdown content with healthcare styling
class MarkdownText extends StatelessWidget {
  final String data;
  final TextStyle? textStyle;
  final bool selectable;
  final double? maxWidth;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const MarkdownText({
    super.key,
    required this.data,
    this.textStyle,
    this.selectable = false,
    this.maxWidth,
    this.physics,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final styleSheet = MarkdownStyleSheet(
      // Text styles
      p: textStyle ?? theme.textTheme.bodyMedium?.copyWith(
        height: 1.6,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      h1: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      
      // Lists
      listBullet: textStyle ?? theme.textTheme.bodyMedium,
      listIndent: 20,
      
      // Code
      code: TextStyle(
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        fontFamily: 'monospace',
        fontSize: 13,
        color: theme.colorScheme.primary,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      
      // Blockquote (for medical notes/warnings)
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: isDark ? Colors.blue[200] : Colors.blue[800],
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(12),
      
      // Tables (for medical data)
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      tableBody: theme.textTheme.bodySmall,
      tableBorder: TableBorder.all(
        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        width: 1,
      ),
      
      // Links
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      
      // Strong/Bold (for important medical info)
      strong: const TextStyle(fontWeight: FontWeight.bold),
      
      // Emphasis
      em: const TextStyle(fontStyle: FontStyle.italic),
    );

    final body = MarkdownBody(
      data: data,
      styleSheet: styleSheet,
      shrinkWrap: shrinkWrap,
      selectable: selectable,
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.parse(href);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: body,
      );
    }

    return body;
  }
}

/// Streaming Markdown Text - Shows markdown text with typing animation
class StreamingMarkdownText extends StatefulWidget {
  final String streamingContent;
  final TextStyle? textStyle;
  final bool showCursor;
  final Duration typingSpeed;
  final VoidCallback? onComplete;

  const StreamingMarkdownText({
    super.key,
    required this.streamingContent,
    this.textStyle,
    this.showCursor = true,
    this.typingSpeed = const Duration(milliseconds: 20),
    this.onComplete,
  });

  @override
  State<StreamingMarkdownText> createState() => _StreamingMarkdownTextState();
}

class _StreamingMarkdownTextState extends State<StreamingMarkdownText> {
  String _displayedContent = '';
  int _currentIndex = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(StreamingMarkdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamingContent != widget.streamingContent) {
      _reset();
      _startTyping();
    }
  }

  void _reset() {
    _displayedContent = '';
    _currentIndex = 0;
    _isComplete = false;
  }

  void _startTyping() {
    if (_isComplete) return;
    
    Future.delayed(widget.typingSpeed, () {
      if (!mounted) return;
      
      if (_currentIndex < widget.streamingContent.length) {
        setState(() {
          _currentIndex++;
          _displayedContent = widget.streamingContent.substring(0, _currentIndex);
        });
        _startTyping();
      } else {
        _isComplete = true;
        widget.onComplete?.call();
      }
    });
  }

  void skipToEnd() {
    setState(() {
      _displayedContent = widget.streamingContent;
      _currentIndex = widget.streamingContent.length;
      _isComplete = true;
    });
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isComplete ? null : skipToEnd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: MarkdownText(
              data: _displayedContent,
              textStyle: widget.textStyle,
            ),
          ),
          if (widget.showCursor && !_isComplete)
            _buildCursor(),
        ],
      ),
    );
  }

  Widget _buildCursor() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value > 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 2,
            height: 16,
            margin: const EdgeInsets.only(left: 2, bottom: 2),
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
      onEnd: () {
        if (mounted && !_isComplete) {
          setState(() {});
        }
      },
    );
  }
}

/// Medical Alert Card - Special formatting for medical warnings/tips
class MedicalAlertCard extends StatelessWidget {
  final String title;
  final String content;
  final MedicalAlertType type;

  const MedicalAlertCard({
    super.key,
    required this.title,
    required this.content,
    this.type = MedicalAlertType.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: type.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: type.color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(type.icon, color: type.color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: type.color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: type.color.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum MedicalAlertType {
  warning(Colors.orange, Icons.warning_amber_rounded),
  danger(Colors.red, Icons.dangerous_rounded),
  info(Colors.blue, Icons.info_outline_rounded),
  success(Colors.green, Icons.check_circle_outline_rounded),
  tip(Colors.purple, Icons.lightbulb_outline_rounded);

  final Color color;
  final IconData icon;

  const MedicalAlertType(this.color, this.icon);

  Color get backgroundColor => color.withOpacity(0.1);
}
