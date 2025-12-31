import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for checking backend server health
class BackendHealthService {
  final http.Client _client;

  BackendHealthService() : _client = http.Client();

  /// Check if backend server is reachable and healthy
  Future<ServerHealthStatus> checkHealth(String serverUrl) async {
    try {
      debugPrint('[BackendHealth] Checking health at: $serverUrl/api/health');

      final response = await _client.get(
        Uri.parse('$serverUrl/api/health'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        final version = data['version'] as String?;

        if (status == 'ok') {
          debugPrint('[BackendHealth] ✅ Server healthy - version: $version');
          return ServerHealthStatus.connected(version: version);
        }
      }

      debugPrint(
        '[BackendHealth] ⚠️ Unexpected response: ${response.statusCode}',
      );
      return ServerHealthStatus(
        isHealthy: false,
        message: 'Server responded with status ${response.statusCode}',
        connectionState: ServerConnectionState.error,
      );
    } on TimeoutException catch (e) {
      debugPrint('[BackendHealth] ❌ Connection timed out: $e');
      return ServerHealthStatus.timeout();
    } on http.ClientException catch (e) {
      debugPrint('[BackendHealth] ❌ Connection failed: $e');

      // Check error message for network vs server issues
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('failed host lookup') ||
          errorMessage.contains('network is unreachable') ||
          errorMessage.contains('no route to host')) {
        return ServerHealthStatus.networkError(details: e.message);
      }

      // Connection refused - server likely not running
      return ServerHealthStatus.serverOffline(serverUrl);
    } catch (e) {
      debugPrint('[BackendHealth] ❌ Unexpected error: $e');
      return ServerHealthStatus(
        isHealthy: false,
        message: 'Unexpected error',
        error: e.toString(),
        connectionState: ServerConnectionState.error,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

/// Connection state types for better UI feedback
enum ServerConnectionState {
  connected,      // Server is healthy and reachable
  connecting,     // Currently checking connection
  serverOffline,  // Can reach network but server not responding
  networkError,   // Cannot establish network connection at all
  timeout,        // Connection timed out
  error,          // Other error
}

/// Health status of the backend server
class ServerHealthStatus {
  final bool isHealthy;
  final String message;
  final String? version;
  final String? error;
  final ServerConnectionState connectionState;

  ServerHealthStatus({
    required this.isHealthy,
    required this.message,
    this.version,
    this.error,
    this.connectionState = ServerConnectionState.error,
  });

  /// Factory for a healthy connection
  factory ServerHealthStatus.connected({String? version}) {
    return ServerHealthStatus(
      isHealthy: true,
      message: 'Connected',
      version: version,
      connectionState: ServerConnectionState.connected,
    );
  }

  /// Factory for server offline
  factory ServerHealthStatus.serverOffline(String serverUrl) {
    return ServerHealthStatus(
      isHealthy: false,
      message: 'Server not responding',
      connectionState: ServerConnectionState.serverOffline,
      error: 'Cannot reach $serverUrl',
    );
  }

  /// Factory for network error
  factory ServerHealthStatus.networkError({String? details}) {
    return ServerHealthStatus(
      isHealthy: false,
      message: 'Network connection failed',
      connectionState: ServerConnectionState.networkError,
      error: details,
    );
  }

  /// Factory for timeout
  factory ServerHealthStatus.timeout() {
    return ServerHealthStatus(
      isHealthy: false,
      message: 'Connection timed out',
      connectionState: ServerConnectionState.timeout,
    );
  }

  String get displayMessage {
    if (isHealthy) {
      final versionInfo = version != null ? ' (v$version)' : '';
      return 'Connected$versionInfo';
    }
    return message;
  }

  /// User-friendly help text based on connection state
  String get helpText {
    switch (connectionState) {
      case ServerConnectionState.connected:
        return '';
      case ServerConnectionState.connecting:
        return 'Checking server connection...';
      case ServerConnectionState.serverOffline:
        return 'Make sure the base server is running (npm start in base/)';
      case ServerConnectionState.networkError:
        return error ?? 'Check hostname or use IP address instead';
      case ServerConnectionState.timeout:
        return 'Server is slow to respond - check if it\'s overloaded';
      case ServerConnectionState.error:
        return error ?? 'An unexpected error occurred';
    }
  }
}
