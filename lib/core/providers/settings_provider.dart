import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/build_settings_service.dart';
import '../services/backend_health_service.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider for BuildSettingsService
final buildSettingsServiceProvider = Provider<BuildSettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BuildSettingsService(prefs);
});

/// Provider for build server URL with persistence
final buildServiceUrlProvider = Provider<String>((ref) {
  final settingsService = ref.watch(buildSettingsServiceProvider);
  final url = settingsService.getServerUrlSync();
  debugPrint('[buildServiceUrlProvider] Loaded URL from storage: $url');
  return url;
});

/// Provider for the backend health service
final backendHealthServiceProvider = Provider<BackendHealthService>((ref) {
  final service = BackendHealthService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for checking server health
/// Pass the server URL to check
final serverHealthProvider = FutureProvider.family<ServerHealthStatus, String>((
  ref,
  serverUrl,
) async {
  final healthService = ref.read(backendHealthServiceProvider);
  return healthService.checkHealth(serverUrl);
});
