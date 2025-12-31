import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:parachute_build/core/theme/design_tokens.dart';
import 'package:parachute_build/core/providers/settings_provider.dart';
import 'package:parachute_build/core/widgets/connection_status_banner.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/project.dart';
import 'project_detail_screen.dart';

/// Provider for fetching projects from the API (uses generic /api/ls endpoint)
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final baseUrl = ref.watch(buildServiceUrlProvider);
  final url = '$baseUrl/api/ls?path=Build/repos';

  try {
    debugPrint('[ProjectsProvider] Fetching from: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      debugPrint('[ProjectsProvider] Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load projects: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final List<dynamic> entriesJson = data['entries'] ?? [];

    // Only show directories as projects
    return entriesJson
        .where((json) => json['type'] == 'directory')
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('[ProjectsProvider] Exception: $e');
    debugPrint('[ProjectsProvider] BaseURL was: $baseUrl');
    throw Exception('Could not connect to server at $baseUrl: $e');
  }
});

/// Screen showing list of projects to work on
class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsProvider);
    final serverUrl = ref.watch(buildServiceUrlProvider);
    final healthAsync = ref.watch(serverHealthProvider(serverUrl));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parachute Build'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Banner
          healthAsync.when(
            data: (health) => ConnectionStatusBanner(
              status: health,
              onRetry: () => ref.invalidate(serverHealthProvider(serverUrl)),
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          // Main Content
          Expanded(
            child: projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }
                return _buildProjectList(context, projects, isDark);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, error, isDark, ref, serverUrl),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProject(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'No projects yet',
              style: TextStyle(
                fontSize: TypographyTokens.headlineMedium,
                fontWeight: FontWeight.w600,
                color: isDark ? BrandColors.nightText : BrandColors.charcoal,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Add a project folder to start building with AI',
              style: TextStyle(
                fontSize: TypographyTokens.bodyMedium,
                color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, bool isDark, WidgetRef ref, String serverUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: BrandColors.error,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Failed to load projects',
              style: TextStyle(
                fontSize: TypographyTokens.headlineMedium,
                fontWeight: FontWeight.w600,
                color: isDark ? BrandColors.nightText : BrandColors.charcoal,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: TypographyTokens.bodyMedium,
                color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? BrandColors.nightSurfaceElevated
                    : BrandColors.stone.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Text(
                'Server: $serverUrl',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySmall,
                  fontFamily: 'monospace',
                  color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(projectsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: Spacing.md),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, List<Project> projects, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.lg),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectCard(
          project: project,
          isDark: isDark,
          onTap: () => _openProject(context, project),
        );
      },
    );
  }

  void _openProject(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  Future<void> _addProject(BuildContext context, WidgetRef ref) async {
    try {
      // Pick a directory
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Project Folder',
      );

      if (result == null) return; // User cancelled

      final baseUrl = ref.read(buildServiceUrlProvider);

      // Extract project name from path
      final projectName = result.split('/').last;

      // Add project via generic symlink API
      final response = await http.post(
        Uri.parse('$baseUrl/api/symlink'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target': result,
          'link': 'Build/repos/$projectName',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Refresh project list
        ref.invalidate(projectsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added project: $projectName'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (response.statusCode == 409) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project with this name already exists'),
              backgroundColor: BrandColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Failed to add project: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: BrandColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

}

/// Card displaying a project
class _ProjectCard extends StatelessWidget {
  final Project project;
  final bool isDark;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? BrandColors.forestDeep : BrandColors.forestMist,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Icon(
            project.isGitRepo ? Icons.folder_special : Icons.folder,
            color: isDark ? BrandColors.nightForest : BrandColors.forest,
          ),
        ),
        title: Text(
          project.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? BrandColors.nightText : BrandColors.charcoal,
          ),
        ),
        subtitle: Text(
          project.path,
          style: TextStyle(
            fontSize: TypographyTokens.bodySmall,
            color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (project.hasClaudeMd)
              Chip(
                label: const Text('CLAUDE.md'),
                padding: EdgeInsets.zero,
                labelStyle: TextStyle(fontSize: TypographyTokens.labelSmall),
              ),
            const SizedBox(width: Spacing.xs),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
