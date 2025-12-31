import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:parachute_build/core/theme/design_tokens.dart';
import '../../projects/models/project.dart';
import '../../projects/screens/project_list_screen.dart';
import '../models/chat_message.dart';
import '../models/stream_event.dart';
import '../services/build_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

/// Main build screen for working on a project
class BuildScreen extends ConsumerStatefulWidget {
  final Project project;

  /// If provided, loads an existing session instead of creating new one
  final String? existingSessionId;

  const BuildScreen({
    super.key,
    required this.project,
    this.existingSessionId,
  });

  @override
  ConsumerState<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends ConsumerState<BuildScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late BuildService _buildService;
  String? _currentSessionId;
  bool _isStreaming = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initService();
    _loadExistingSession();
  }

  void _initService() {
    final baseUrl = ref.read(buildServiceUrlProvider);
    _buildService = BuildService(baseUrl: baseUrl);
  }

  Future<void> _loadExistingSession() async {
    if (widget.existingSessionId == null) return;

    setState(() => _isLoading = true);

    try {
      final sessionWithMessages = await _buildService.getSession(widget.existingSessionId!);
      if (sessionWithMessages != null) {
        setState(() {
          _currentSessionId = widget.existingSessionId;
          _messages.addAll(sessionWithMessages.messages);
        });
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _buildService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Motion.standard,
        curve: Motion.settling,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (_isStreaming) return;

    // Create session ID if needed
    _currentSessionId ??= const Uuid().v4();

    // Add user message
    final userMessage = ChatMessage.user(
      sessionId: _currentSessionId!,
      text: text,
    );
    setState(() {
      _messages.add(userMessage);
      _isStreaming = true;
    });
    _scrollToBottom();

    // Create assistant placeholder
    final assistantMessage = ChatMessage.assistantPlaceholder(
      sessionId: _currentSessionId!,
    );
    setState(() {
      _messages.add(assistantMessage);
    });

    try {
      // Stream response
      final stream = _buildService.streamChat(
        sessionId: _currentSessionId!,
        message: text,
        workingDirectory: widget.project.path,
      );

      List<MessageContent> contentParts = [];
      String currentText = '';

      await for (final event in stream) {
        switch (event.type) {
          case StreamEventType.session:
            // Session created/resumed
            if (event.sessionId != null) {
              _currentSessionId = event.sessionId;
            }
            break;

          case StreamEventType.text:
            if (event.textContent != null) {
              currentText += event.textContent!;
              _updateAssistantMessage(contentParts, currentText);
            }
            break;

          case StreamEventType.thinking:
            if (event.thinkingContent != null) {
              contentParts.add(MessageContent.thinking(event.thinkingContent!));
              _updateAssistantMessage(contentParts, currentText);
            }
            break;

          case StreamEventType.toolUse:
            if (event.toolCall != null) {
              contentParts.add(MessageContent.toolUse(event.toolCall!));
              _updateAssistantMessage(contentParts, currentText);
            }
            break;

          case StreamEventType.toolResult:
            // Update the tool call with its result
            if (event.toolUseId != null) {
              final toolIndex = contentParts.indexWhere(
                (c) => c.type == ContentType.toolUse && c.toolCall?.id == event.toolUseId,
              );
              if (toolIndex >= 0) {
                final tool = contentParts[toolIndex].toolCall!;
                contentParts[toolIndex] = MessageContent.toolUse(
                  tool.withResult(
                    event.toolResultContent ?? '',
                    isError: event.toolResultIsError,
                  ),
                );
                _updateAssistantMessage(contentParts, currentText);
              }
            }
            break;

          case StreamEventType.done:
            setState(() => _isStreaming = false);
            break;

          case StreamEventType.error:
            setState(() {
              _isStreaming = false;
              // Replace placeholder with error message
              if (_messages.isNotEmpty && _messages.last.isStreaming) {
                _messages.removeLast();
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(event.errorMessage ?? 'Unknown error'),
                  backgroundColor: BrandColors.error,
                ),
              );
            }
            break;

          default:
            break;
        }
      }
    } catch (e) {
      setState(() {
        _isStreaming = false;
        if (_messages.isNotEmpty && _messages.last.isStreaming) {
          _messages.removeLast();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    }
  }

  void _updateAssistantMessage(List<MessageContent> contentParts, String currentText) {
    if (_messages.isEmpty) return;

    // Build full content list
    final allContent = [...contentParts];
    if (currentText.isNotEmpty) {
      allContent.add(MessageContent.text(currentText));
    }

    // Update the last message
    final updatedMessage = _messages.last.copyWith(
      content: allContent,
      isStreaming: true,
    );

    setState(() {
      _messages[_messages.length - 1] = updatedMessage;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.displayName,
              style: const TextStyle(fontSize: TypographyTokens.titleMedium),
            ),
            Text(
              widget.project.path,
              style: TextStyle(
                fontSize: TypographyTokens.labelSmall,
                color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New session',
            onPressed: () {
              setState(() {
                _messages.clear();
                _currentSessionId = null;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(Spacing.lg),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(message: _messages[index]);
                        },
                      ),
          ),

          // Input
          ChatInput(
            onSend: _sendMessage,
            enabled: !_isStreaming && !_isLoading,
            hintText: 'Message ${widget.project.displayName}...',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 48,
              color: isDark ? BrandColors.nightForest : BrandColors.forest,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Ready to build',
              style: TextStyle(
                fontSize: TypographyTokens.headlineMedium,
                fontWeight: FontWeight.w600,
                color: isDark ? BrandColors.nightText : BrandColors.charcoal,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Ask questions, generate code, or explore the codebase',
              style: TextStyle(
                fontSize: TypographyTokens.bodyMedium,
                color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.project.hasClaudeMd) ...[
              const SizedBox(height: Spacing.lg),
              Chip(
                avatar: Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: isDark ? BrandColors.nightForest : BrandColors.forest,
                ),
                label: const Text('Using project CLAUDE.md'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
