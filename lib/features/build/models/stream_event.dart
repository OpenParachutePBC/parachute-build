import 'dart:convert';
import 'chat_message.dart';

/// Type of SSE stream event from the agent backend
enum StreamEventType {
  session,
  init,
  text,
  thinking,
  toolUse,
  toolResult,
  done,
  error,
  unknown,
}

/// Parsed SSE event from the chat stream
class StreamEvent {
  final StreamEventType type;
  final Map<String, dynamic> data;

  const StreamEvent({
    required this.type,
    required this.data,
  });

  static StreamEvent? parse(String line) {
    if (!line.startsWith('data: ')) return null;

    final jsonStr = line.substring(6).trim();
    if (jsonStr.isEmpty || jsonStr == '[DONE]') {
      return const StreamEvent(
        type: StreamEventType.done,
        data: {},
      );
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final typeStr = json['type'] as String? ?? 'unknown';

      StreamEventType type;
      switch (typeStr) {
        case 'session':
          type = StreamEventType.session;
          break;
        case 'init':
          type = StreamEventType.init;
          break;
        case 'text':
          type = StreamEventType.text;
          break;
        case 'thinking':
          type = StreamEventType.thinking;
          break;
        case 'tool_use':
          type = StreamEventType.toolUse;
          break;
        case 'tool_result':
          type = StreamEventType.toolResult;
          break;
        case 'done':
          type = StreamEventType.done;
          break;
        case 'error':
          type = StreamEventType.error;
          break;
        default:
          type = StreamEventType.unknown;
      }

      return StreamEvent(type: type, data: json);
    } catch (e) {
      return StreamEvent(
        type: StreamEventType.error,
        data: {'error': 'Failed to parse event: $e', 'raw': jsonStr},
      );
    }
  }

  String? get sessionId => data['sessionId'] as String?;
  String? get sessionTitle => data['title'] as String?;
  String? get textContent => data['content'] as String?;
  String? get thinkingContent => data['content'] as String?;

  ToolCall? get toolCall {
    final tool = data['tool'] as Map<String, dynamic>?;
    if (tool == null) return null;
    return ToolCall.fromJson(tool);
  }

  String? get errorMessage => data['error'] as String?;
  String? get toolUseId => data['toolUseId'] as String?;
  String? get toolResultContent => data['content'] as String?;
  bool get toolResultIsError => data['isError'] as bool? ?? false;
  int? get durationMs => data['durationMs'] as int?;
}
