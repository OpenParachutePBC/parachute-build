import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/build_session.dart';
import '../models/chat_message.dart';
import '../models/stream_event.dart';
import '../../projects/models/project.dart';

/// Service for communicating with parachute-base for Build module
class BuildService {
  final String baseUrl;
  final http.Client _client;

  static const requestTimeout = Duration(seconds: 30);

  BuildService({required this.baseUrl}) : _client = http.Client();

  // ============================================================
  // Projects
  // ============================================================

  /// List all projects in the Build folder
  Future<List<Project>> getProjects() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/build/projects'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to get projects: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['projects'] is List) {
        data = decoded['projects'] as List<dynamic>;
      } else {
        data = [];
      }
      return data
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[BuildService] Error getting projects: $e');
      rethrow;
    }
  }

  // ============================================================
  // Sessions
  // ============================================================

  /// Get sessions for a specific project (by working directory)
  Future<List<BuildSession>> getSessions({String? workingDirectory}) async {
    try {
      var url = '$baseUrl/api/chat?module=build';
      if (workingDirectory != null) {
        url += '&workingDirectory=${Uri.encodeComponent(workingDirectory)}';
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to get sessions: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['sessions'] is List) {
        data = decoded['sessions'] as List<dynamic>;
      } else {
        data = [];
      }
      return data
          .map((json) => BuildSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[BuildService] Error getting sessions: $e');
      rethrow;
    }
  }

  /// Get a specific session with messages
  Future<BuildSessionWithMessages?> getSession(String sessionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/chat/${Uri.encodeComponent(sessionId)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to get session: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return BuildSessionWithMessages.fromJson(data);
    } catch (e) {
      debugPrint('[BuildService] Error getting session: $e');
      rethrow;
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/chat/${Uri.encodeComponent(sessionId)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete session: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BuildService] Error deleting session: $e');
      rethrow;
    }
  }

  // ============================================================
  // Streaming Chat
  // ============================================================

  /// Send a message and receive streaming response
  Stream<StreamEvent> streamChat({
    required String sessionId,
    required String message,
    required String workingDirectory,
  }) async* {
    debugPrint('[BuildService] Starting stream chat');
    debugPrint('[BuildService] Session: $sessionId');
    debugPrint('[BuildService] Working directory: $workingDirectory');

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/chat'),
    );

    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'message': message,
      'sessionId': sessionId,
      'module': 'build',
      'workingDirectory': workingDirectory,
    });

    const connectionTimeout = Duration(seconds: 30);
    const chunkTimeout = Duration(seconds: 60);

    try {
      final streamedResponse = await _client.send(request).timeout(
        connectionTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Connection to server timed out after ${connectionTimeout.inSeconds}s',
          );
        },
      );

      if (streamedResponse.statusCode != 200) {
        yield StreamEvent(
          type: StreamEventType.error,
          data: {'error': 'Server returned ${streamedResponse.statusCode}'},
        );
        return;
      }

      String buffer = '';

      await for (final chunk in streamedResponse.stream
          .timeout(chunkTimeout, onTimeout: (sink) {
            sink.addError(TimeoutException(
              'No data received for ${chunkTimeout.inSeconds}s',
            ));
            sink.close();
          })
          .transform(utf8.decoder)) {
        buffer += chunk;

        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) continue;

          final event = StreamEvent.parse(line);
          if (event != null) {
            yield event;

            if (event.type == StreamEventType.done ||
                event.type == StreamEventType.error) {
              return;
            }
          }
        }
      }

      if (buffer.trim().isNotEmpty) {
        final event = StreamEvent.parse(buffer.trim());
        if (event != null) {
          yield event;
        }
      }
    } catch (e) {
      debugPrint('[BuildService] Stream error: $e');
      yield StreamEvent(
        type: StreamEventType.error,
        data: {'error': e.toString()},
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// A session with its messages
class BuildSessionWithMessages {
  final BuildSession session;
  final List<ChatMessage> messages;

  const BuildSessionWithMessages({
    required this.session,
    required this.messages,
  });

  factory BuildSessionWithMessages.fromJson(Map<String, dynamic> json) {
    final session = BuildSession.fromJson(json);

    final messagesList = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesList.map((m) {
      final msg = m as Map<String, dynamic>;
      return ChatMessage.fromJson({
        ...msg,
        'sessionId': session.id,
      });
    }).toList();

    return BuildSessionWithMessages(
      session: session,
      messages: messages,
    );
  }
}
