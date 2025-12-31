/// Represents a build session for a project
class BuildSession {
  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int messageCount;

  /// Working directory (the project path)
  final String? workingDirectory;

  const BuildSession({
    required this.id,
    this.title,
    required this.createdAt,
    this.updatedAt,
    this.messageCount = 0,
    this.workingDirectory,
  });

  factory BuildSession.fromJson(Map<String, dynamic> json) {
    final updatedAtStr = json['updatedAt'] as String? ?? json['lastAccessed'] as String?;

    return BuildSession(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : null,
      messageCount: json['messageCount'] as int? ?? 0,
      workingDirectory: json['workingDirectory'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'messageCount': messageCount,
    'workingDirectory': workingDirectory,
  };

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return 'New Session';
  }

  /// Get just the project name from working directory
  String? get projectName {
    if (workingDirectory == null) return null;
    final parts = workingDirectory!.split('/');
    return parts.isNotEmpty ? parts.last : null;
  }

  BuildSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? workingDirectory,
  }) {
    return BuildSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      workingDirectory: workingDirectory ?? this.workingDirectory,
    );
  }
}
