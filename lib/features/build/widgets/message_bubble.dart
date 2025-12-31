import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:parachute_build/core/theme/design_tokens.dart';
import '../models/chat_message.dart';

/// A chat message bubble with markdown support
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        bottom: Spacing.sm,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? (isDark ? BrandColors.nightForest : BrandColors.forest)
                : (isDark ? BrandColors.nightSurfaceElevated : BrandColors.stone),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(Radii.lg),
              topRight: const Radius.circular(Radii.lg),
              bottomLeft: Radius.circular(isUser ? Radii.lg : Radii.sm),
              bottomRight: Radius.circular(isUser ? Radii.sm : Radii.lg),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tool calls (collapsed)
              if (message.toolCalls.isNotEmpty)
                _ToolCallsSection(toolCalls: message.toolCalls, isDark: isDark),

              // Text content
              if (message.textContent.isNotEmpty)
                _buildTextContent(context, isUser, isDark),

              // Streaming indicator
              if (message.isStreaming && message.content.isEmpty)
                _buildStreamingIndicator(isDark),

              // Copy button
              if (message.textContent.isNotEmpty)
                _CopyButton(text: message.textContent, isDark: isDark, isUser: isUser),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, bool isUser, bool isDark) {
    final textColor = isUser
        ? Colors.white
        : (isDark ? BrandColors.nightText : BrandColors.charcoal);

    return Padding(
      padding: Spacing.cardPadding,
      child: isUser
          ? SelectableText(
              message.textContent,
              style: TextStyle(
                color: textColor,
                fontSize: TypographyTokens.bodyMedium,
                height: TypographyTokens.lineHeightNormal,
              ),
            )
          : MarkdownBody(
              data: message.textContent,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: textColor,
                  fontSize: TypographyTokens.bodyMedium,
                  height: TypographyTokens.lineHeightNormal,
                ),
                code: TextStyle(
                  color: textColor,
                  backgroundColor: isDark ? BrandColors.nightSurface : BrandColors.cream,
                  fontFamily: 'monospace',
                  fontSize: TypographyTokens.bodySmall,
                ),
                codeblockDecoration: BoxDecoration(
                  color: isDark ? BrandColors.nightSurface : BrandColors.cream,
                  borderRadius: Radii.badge,
                ),
                h1: TextStyle(color: textColor, fontSize: TypographyTokens.headlineLarge, fontWeight: FontWeight.bold),
                h2: TextStyle(color: textColor, fontSize: TypographyTokens.headlineMedium, fontWeight: FontWeight.bold),
                h3: TextStyle(color: textColor, fontSize: TypographyTokens.headlineSmall, fontWeight: FontWeight.bold),
                listBullet: TextStyle(color: textColor),
              ),
            ),
    );
  }

  Widget _buildStreamingIndicator(bool isDark) {
    return Padding(
      padding: Spacing.cardPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: isDark ? BrandColors.nightTurquoise : BrandColors.turquoise),
          const SizedBox(width: 4),
          _PulsingDot(
            color: isDark ? BrandColors.nightTurquoise : BrandColors.turquoise,
            delay: const Duration(milliseconds: 150),
          ),
          const SizedBox(width: 4),
          _PulsingDot(
            color: isDark ? BrandColors.nightTurquoise : BrandColors.turquoise,
            delay: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

/// Collapsed section showing tool calls
class _ToolCallsSection extends StatefulWidget {
  final List<ToolCall> toolCalls;
  final bool isDark;

  const _ToolCallsSection({required this.toolCalls, required this.isDark});

  @override
  State<_ToolCallsSection> createState() => _ToolCallsSectionState();
}

class _ToolCallsSectionState extends State<_ToolCallsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood;

    return Padding(
      padding: const EdgeInsets.only(left: Spacing.md, right: Spacing.md, top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.toolCalls.length} tool call${widget.toolCalls.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: TypographyTokens.labelSmall,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded)
            ...widget.toolCalls.map((tool) => Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: widget.isDark ? BrandColors.nightSurface : BrandColors.cream,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: TextStyle(
                        fontSize: TypographyTokens.labelMedium,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? BrandColors.nightText : BrandColors.charcoal,
                      ),
                    ),
                    if (tool.summary.isNotEmpty)
                      Text(
                        tool.summary,
                        style: TextStyle(
                          fontSize: TypographyTokens.labelSmall,
                          color: textColor,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}

/// Animated pulsing dot for streaming indicator
class _PulsingDot extends StatefulWidget {
  final Color color;
  final Duration delay;

  const _PulsingDot({
    required this.color,
    this.delay = Duration.zero,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Copy button with visual feedback
class _CopyButton extends StatefulWidget {
  final String text;
  final bool isDark;
  final bool isUser;

  const _CopyButton({required this.text, required this.isDark, required this.isUser});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isUser
        ? Colors.white.withValues(alpha: 0.7)
        : (widget.isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood);

    return Padding(
      padding: const EdgeInsets.only(left: Spacing.sm, right: Spacing.sm, bottom: Spacing.xs),
      child: GestureDetector(
        onTap: _copyToClipboard,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check : Icons.copy,
              size: 14,
              color: _copied
                  ? (widget.isDark ? BrandColors.nightTurquoise : BrandColors.turquoise)
                  : iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'Copied' : 'Copy',
              style: TextStyle(
                fontSize: TypographyTokens.labelSmall,
                color: _copied
                    ? (widget.isDark ? BrandColors.nightTurquoise : BrandColors.turquoise)
                    : iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
