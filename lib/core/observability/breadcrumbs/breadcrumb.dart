/// Semantic category for a breadcrumb entry.
enum BreadcrumbCategory {
  navigation,
  api,
  userAction,
  auth,
  state,
  scanner,
  system;

  String get label => name;
}

/// Immutable structured breadcrumb entry.
final class Breadcrumb {
  final String message;
  final BreadcrumbCategory category;
  final DateTime timestamp;
  final Map<String, Object> metadata;

  Breadcrumb({
    required this.message,
    required this.category,
    Map<String, Object>? metadata,
  })  : timestamp = DateTime.now(),
        metadata = metadata ?? const {};

  String toLogString() {
    final meta = metadata.isEmpty
        ? ''
        : '  ${metadata.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    return '[${category.label}] $message$meta';
  }
}
