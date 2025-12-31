import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parachute_build/core/theme/design_tokens.dart';
import 'package:parachute_build/core/providers/settings_provider.dart';

/// Settings screen for Build app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _serverUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(buildServiceUrlProvider);
    _serverUrlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveServerUrl() async {
    setState(() => _isLoading = true);

    try {
      final settingsService = ref.read(buildSettingsServiceProvider);
      await settingsService.setServerUrl(_serverUrlController.text.trim());

      // Invalidate providers to reload with new URL
      ref.invalidate(buildServiceUrlProvider);
      ref.invalidate(serverHealthProvider(_serverUrlController.text.trim()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server URL saved successfully'),
            backgroundColor: BrandColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving URL: $e'),
            backgroundColor: BrandColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildServerStatusIndicator() {
    final serverUrl = _serverUrlController.text.trim();
    if (serverUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final healthAsync = ref.watch(serverHealthProvider(serverUrl));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return healthAsync.when(
      data: (health) {
        final statusColor =
            health.isHealthy ? BrandColors.success : BrandColors.error;

        return Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                health.isHealthy ? Icons.check_circle : Icons.error,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      health.displayMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: TypographyTokens.bodySmall,
                        color: statusColor,
                      ),
                    ),
                    if (health.helpText.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        health.helpText,
                        style: TextStyle(
                          fontSize: TypographyTokens.labelSmall,
                          color: isDark
                              ? BrandColors.nightTextSecondary
                              : BrandColors.driftwood,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: BrandColors.turquoise.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: BrandColors.turquoise, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(BrandColors.turquoise),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Text(
              'Checking server status...',
              style: TextStyle(
                fontSize: TypographyTokens.bodySmall,
                color: BrandColors.turquoise,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: BrandColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: BrandColors.warning, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: BrandColors.warning, size: 20),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                'Error checking server: $error',
                style: TextStyle(
                  fontSize: TypographyTokens.labelSmall,
                  color: BrandColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          // Server Configuration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_outlined,
                        color: isDark ? BrandColors.nightText : BrandColors.forest,
                      ),
                      const SizedBox(width: Spacing.md),
                      Text(
                        'Server Configuration',
                        style: TextStyle(
                          fontSize: TypographyTokens.headlineSmall,
                          fontWeight: FontWeight.bold,
                          color: isDark ? BrandColors.nightText : BrandColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Connect to your Parachute Base server',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySmall,
                      color: isDark
                          ? BrandColors.nightTextSecondary
                          : BrandColors.driftwood,
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  TextField(
                    controller: _serverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://localhost:3333',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                      helperText: 'Use hostname (e.g., mbp.local:3333) or IP address',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: Spacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _saveServerUrl,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? 'Saving...' : 'Save URL'),
                          style: FilledButton.styleFrom(
                            backgroundColor: BrandColors.forest,
                            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      FilledButton.icon(
                        onPressed: () {
                          ref.invalidate(
                            serverHealthProvider(_serverUrlController.text.trim()),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Test'),
                        style: FilledButton.styleFrom(
                          backgroundColor: BrandColors.turquoise,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.lg,
                            vertical: Spacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  _buildServerStatusIndicator(),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // About Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? BrandColors.nightText : BrandColors.forest,
                      ),
                      const SizedBox(width: Spacing.md),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: TypographyTokens.headlineSmall,
                          fontWeight: FontWeight.bold,
                          color: isDark ? BrandColors.nightText : BrandColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0+1'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Description'),
                    subtitle: const Text(
                      'Claude Code-like development assistant for working with codebases',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
