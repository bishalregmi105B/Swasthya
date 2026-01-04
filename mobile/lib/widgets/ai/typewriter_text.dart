import 'dart:async';
import 'package:flutter/material.dart';

/// Typewriter Text Widget - Animates text appearing character by character
/// Adapted from Ashlya Academy for Swasthya healthcare AI responses
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration characterDelay;
  final VoidCallback? onComplete;
  final bool autoStart;
  final int? maxLines;
  final TextAlign textAlign;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.characterDelay = const Duration(milliseconds: 20),
    this.onComplete,
    this.autoStart = true,
    this.maxLines,
    this.textAlign = TextAlign.start,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      _startTyping();
    }
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _reset();
      if (widget.autoStart) {
        _startTyping();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _displayedText = '';
    _currentIndex = 0;
    _isComplete = false;
  }

  void _startTyping() {
    if (widget.text.isEmpty) {
      _isComplete = true;
      widget.onComplete?.call();
      return;
    }

    _timer = Timer.periodic(widget.characterDelay, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
        _isComplete = true;
        widget.onComplete?.call();
      }
    });
  }

  void skipToEnd() {
    _timer?.cancel();
    setState(() {
      _displayedText = widget.text;
      _currentIndex = widget.text.length;
      _isComplete = true;
    });
    widget.onComplete?.call();
  }

  void restart() {
    _reset();
    _startTyping();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isComplete ? null : skipToEnd,
      child: Text(
        _displayedText,
        style: widget.style,
        maxLines: widget.maxLines,
        textAlign: widget.textAlign,
        overflow: widget.maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }
}

/// Animated AI Response Widget - Displays AI text with typewriter effect and loading state
class AnimatedAIResponse extends StatefulWidget {
  final String text;
  final bool isLoading;
  final TextStyle? textStyle;
  final Color? loadingColor;
  
  const AnimatedAIResponse({
    super.key,
    required this.text,
    this.isLoading = false,
    this.textStyle,
    this.loadingColor,
  });

  @override
  State<AnimatedAIResponse> createState() => _AnimatedAIResponseState();
}

class _AnimatedAIResponseState extends State<AnimatedAIResponse>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              const SizedBox(width: 4),
              _buildDot(1),
              const SizedBox(width: 4),
              _buildDot(2),
            ],
          );
        },
      );
    }

    return TypewriterText(
      text: widget.text,
      style: widget.textStyle,
      characterDelay: const Duration(milliseconds: 15),
    );
  }

  Widget _buildDot(int index) {
    final color = widget.loadingColor ?? Theme.of(context).primaryColor;
    final delay = index * 0.2;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final value = (_pulseController.value + delay) % 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Markdown-aware typewriter that preserves formatting
class MarkdownTypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? baseStyle;
  final Duration characterDelay;
  final VoidCallback? onComplete;

  const MarkdownTypewriterText({
    super.key,
    required this.text,
    this.baseStyle,
    this.characterDelay = const Duration(milliseconds: 25),
    this.onComplete,
  });

  @override
  State<MarkdownTypewriterText> createState() => _MarkdownTypewriterTextState();
}

class _MarkdownTypewriterTextState extends State<MarkdownTypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(MarkdownTypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayedText = '';
      _currentIndex = 0;
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    if (widget.text.isEmpty) {
      widget.onComplete?.call();
      return;
    }

    _timer = Timer.periodic(widget.characterDelay, (timer) {
      if (_currentIndex < widget.text.length) {
        // Handle markdown tokens - reveal them together
        final remaining = widget.text.substring(_currentIndex);
        int advance = 1;

        // Check for markdown patterns
        if (remaining.startsWith('**') || remaining.startsWith('__')) {
          // Find closing marker
          final marker = remaining.substring(0, 2);
          final closeIdx = remaining.indexOf(marker, 2);
          if (closeIdx > 0) {
            advance = closeIdx + 2;
          }
        } else if (remaining.startsWith('*') || remaining.startsWith('_')) {
          // Find closing marker
          final marker = remaining.substring(0, 1);
          final closeIdx = remaining.indexOf(marker, 1);
          if (closeIdx > 0) {
            advance = closeIdx + 1;
          }
        } else if (remaining.startsWith('\n')) {
          advance = 1;
        }

        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + advance);
          _currentIndex += advance;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.baseStyle,
    );
  }
}
