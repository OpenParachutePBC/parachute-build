import 'package:flutter/material.dart';
import 'package:parachute_build/core/theme/design_tokens.dart';
import '../services/backend_health_service.dart';

/// Banner showing connection status when server is not reachable
class ConnectionStatusBanner extends StatelessWidget {
  final ServerHealthStatus status;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  const ConnectionStatusBanner({
    super.key,
    required this.status,
    required this.onRetry,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Don't show banner if connected
    if (status.isHealthy) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (status.connectionState) {
      case ServerConnectionState.timeout:
        icon = Icons.hourglass_empty;
        bgColor = BrandColors.warning;
        iconColor = BrandColors.warning;
        break;
      case ServerConnectionState.networkError:
        icon = Icons.wifi_off;
        bgColor = BrandColors.error;
        iconColor = BrandColors.error;
        break;
      case ServerConnectionState.serverOffline:
        icon = Icons.cloud_off;
        bgColor = BrandColors.warning;
        iconColor = BrandColors.warning;
        break;
      default:
        icon = Icons.error_outline;
        bgColor = BrandColors.error;
        iconColor = BrandColors.error;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: isDark ? 0.2 : 0.1),
        border: Border(
          bottom: BorderSide(
            color: bgColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status.displayMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: TypographyTokens.bodyMedium,
                    color: isDark ? BrandColors.nightText : BrandColors.charcoal,
                  ),
                ),
                if (status.helpText.isNotEmpty) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    status.helpText,
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySmall,
                      color: isDark
                          ? BrandColors.nightTextSecondary
                          : BrandColors.driftwood,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: iconColor,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onSettings,
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Settings'),
            style: TextButton.styleFrom(
              foregroundColor: iconColor,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
