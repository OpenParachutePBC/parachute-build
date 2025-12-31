import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting build app settings
class BuildSettingsService {
  static const String _serverUrlKey = 'build_server_url';
  static const String _defaultServerUrl = 'http://localhost:3333';

  final SharedPreferences _prefs;

  BuildSettingsService(this._prefs);

  /// Get the build server URL
  Future<String> getServerUrl() async {
    return _prefs.getString(_serverUrlKey) ?? _defaultServerUrl;
  }

  /// Set the build server URL
  Future<void> setServerUrl(String url) async {
    await _prefs.setString(_serverUrlKey, url);
  }

  /// Get the server URL synchronously (returns cached value)
  String getServerUrlSync() {
    return _prefs.getString(_serverUrlKey) ?? _defaultServerUrl;
  }
}
