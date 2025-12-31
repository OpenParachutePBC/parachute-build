/// A project/repo that can be worked on in Build
class Project {
  /// Project name (directory name)
  final String name;

  /// Full path to the project directory
  final String path;

  /// Relative path within the vault (e.g., "Build/repos/myproject")
  final String relativePath;

  /// Whether this project has a CLAUDE.md file
  final bool hasClaudeMd;

  /// Whether this is a git repository
  final bool isGitRepo;

  /// Whether this is a symlink
  final bool isSymlink;

  /// Target path if this is a symlink
  final String? symlinkTarget;

  /// Last modified time
  final DateTime? lastModified;

  /// Number of sessions for this project
  final int sessionCount;

  const Project({
    required this.name,
    required this.path,
    required this.relativePath,
    this.hasClaudeMd = false,
    this.isGitRepo = false,
    this.isSymlink = false,
    this.symlinkTarget,
    this.lastModified,
    this.sessionCount = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'] as String,
      path: json['path'] as String,
      relativePath: json['relativePath'] as String? ?? '',
      hasClaudeMd: json['hasClaudeMd'] as bool? ?? false,
      isGitRepo: json['isGitRepo'] as bool? ?? false,
      isSymlink: json['isSymlink'] as bool? ?? false,
      symlinkTarget: json['symlinkTarget'] as String?,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      sessionCount: json['sessionCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'relativePath': relativePath,
    'hasClaudeMd': hasClaudeMd,
    'isGitRepo': isGitRepo,
    'isSymlink': isSymlink,
    'symlinkTarget': symlinkTarget,
    'lastModified': lastModified?.toIso8601String(),
    'sessionCount': sessionCount,
  };

  /// Display name (just the directory name)
  String get displayName => name;
}
