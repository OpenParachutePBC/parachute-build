import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:parachute_build/core/theme/design_tokens.dart';
import '../models/project.dart';
import 'project_list_screen.dart';
import '../../build/screens/build_screen.dart';
import '../../build/models/build_session.dart';

/// Provider to fetch file content
final fileContentProvider = FutureProvider.family<String?, String>((ref, path) async {
  final baseUrl = ref.watch(buildServiceUrlProvider);

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/read?path=${Uri.encodeComponent(path)}'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) {
      return null; // File doesn't exist
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to read file: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['content'] as String?;
  } catch (e) {
    if (e.toString().contains('404')) return null;
    rethrow;
  }
});

/// Provider to fetch sessions for a project
final projectSessionsProvider = FutureProvider.family<List<BuildSession>, String>((ref, workingDirectory) async {
  final baseUrl = ref.watch(buildServiceUrlProvider);

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/chat?module=build'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to load sessions: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final List<dynamic> sessionsJson = data['sessions'] ?? [];

    // Filter sessions for this project's working directory
    return sessionsJson
        .map((json) => BuildSession.fromJson(json as Map<String, dynamic>))
        .where((session) => session.workingDirectory == workingDirectory)
        .toList();
  } catch (e) {
    return []; // Return empty list on error
  }
});

/// Screen showing project details, docs, and sessions
class ProjectDetailScreen extends ConsumerWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build the relative path for CLAUDE.md and README.md
    final claudePath = '${project.relativePath}/CLAUDE.md';
    final readmePath = '${project.relativePath}/README.md';

    final claudeContent = ref.watch(fileContentProvider(claudePath));
    final readmeContent = ref.watch(fileContentProvider(readmePath));
    final sessions = ref.watch(projectSessionsProvider(project.path));

    return Scaffold(
      appBar: AppBar(
        title: Text(project.displayName),
        actions: [
          if (project.isGitRepo)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: Chip(
                avatar: Icon(Icons.source, size: 16),
                label: const Text('Git'),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project path
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: isDark ? BrandColors.charcoal : BrandColors.stone,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: isDark ? BrandColors.nightForest : BrandColors.forest,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      project.path,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: TypographyTokens.bodySmall,
                        color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // Sessions section
            _buildSessionsSection(context, ref, sessions, isDark),

            const SizedBox(height: Spacing.xl),

            // CLAUDE.md section
            if (project.hasClaudeMd) ...[
              _buildDocSection(
                context,
                title: 'CLAUDE.md',
                icon: Icons.smart_toy_outlined,
                content: claudeContent,
                isDark: isDark,
              ),
              const SizedBox(height: Spacing.lg),
            ],

            // README.md section
            _buildDocSection(
              context,
              title: 'README.md',
              icon: Icons.description_outlined,
              content: readmeContent,
              isDark: isDark,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewSession(context),
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }

  Widget _buildSessionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BuildSession>> sessions,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: isDark ? BrandColors.nightForest : BrandColors.forest,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Sessions',
              style: TextStyle(
                fontSize: TypographyTokens.titleMedium,
                fontWeight: FontWeight.w600,
                color: isDark ? BrandColors.nightText : BrandColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        sessions.when(
          data: (sessionList) {
            if (sessionList.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? BrandColors.charcoal : BrandColors.stone,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Center(
                  child: Text(
                    'No sessions yet. Start a new session to begin.',
                    style: TextStyle(
                      color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: sessionList.map((session) {
                return Card(
                  margin: const EdgeInsets.only(bottom: Spacing.sm),
                  child: ListTile(
                    leading: Icon(
                      Icons.chat,
                      color: isDark ? BrandColors.nightForest : BrandColors.forest,
                    ),
                    title: Text(
                      session.title ?? 'Untitled Session',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatDate(session.createdAt),
                      style: TextStyle(
                        fontSize: TypographyTokens.labelSmall,
                        color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openSession(context, session),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading sessions: $e'),
        ),
      ],
    );
  }

  Widget _buildDocSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required AsyncValue<String?> content,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: isDark ? BrandColors.nightForest : BrandColors.forest),
            const SizedBox(width: Spacing.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: TypographyTokens.titleMedium,
                fontWeight: FontWeight.w600,
                color: isDark ? BrandColors.nightText : BrandColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        content.when(
          data: (text) {
            if (text == null) {
              return Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? BrandColors.charcoal : BrandColors.stone,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Center(
                  child: Text(
                    'No $title found',
                    style: TextStyle(
                      color: isDark ? BrandColors.nightTextSecondary : BrandColors.driftwood,
                    ),
                  ),
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: isDark ? BrandColors.charcoal : Colors.white,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                  color: isDark ? BrandColors.nightSurfaceElevated : BrandColors.stone,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: Markdown(
                  data: text,
                  padding: const EdgeInsets.all(Spacing.md),
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: isDark ? BrandColors.nightText : BrandColors.charcoal,
                    ),
                    h1: TextStyle(
                      color: isDark ? BrandColors.nightText : BrandColors.charcoal,
                    ),
                    h2: TextStyle(
                      color: isDark ? BrandColors.nightText : BrandColors.charcoal,
                    ),
                    h3: TextStyle(
                      color: isDark ? BrandColors.nightText : BrandColors.charcoal,
                    ),
                    code: TextStyle(
                      backgroundColor: isDark ? BrandColors.nightSurface : BrandColors.stone,
                      color: isDark ? BrandColors.nightForest : BrandColors.forest,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: isDark ? BrandColors.nightSurface : BrandColors.stone,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return '${date.month}/${date.day}/${date.year}';
  }

  void _startNewSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BuildScreen(project: project),
      ),
    );
  }

  void _openSession(BuildContext context, BuildSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BuildScreen(
          project: project,
          existingSessionId: session.id,
        ),
      ),
    );
  }
}
