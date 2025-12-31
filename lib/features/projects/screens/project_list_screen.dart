import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:parachute_build/core/theme/design_tokens.dart';
import '../models/project.dart';
import 'project_detail_screen.dart';

/// Provider for the build service URL
final buildServiceUrlProvider = StateProvider<String>((ref) => 'http://localhost:3333');

/// Provider for fetching projects from the API (uses generic /api/ls endpoint)
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final baseUrl = ref.watch(buildServiceUrlProvider);

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ls?path=Build/repos'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
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
    throw Exception('Could not connect to server: $e');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context, ref),
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return _buildEmptyState(context, isDark);
          }
          return _buildProjectList(context, projects, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error, isDark, ref),
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

  Widget _buildErrorState(BuildContext context, Object error, bool isDark, WidgetRef ref) {
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
            const SizedBox(height: Spacing.lg),
            ElevatedButton(
              onPressed: () => ref.invalidate(projectsProvider),
              child: const Text('Retry'),
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

  void _showSettings(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(buildServiceUrlProvider),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'http://localhost:3333',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(buildServiceUrlProvider.notifier).state = controller.text;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
