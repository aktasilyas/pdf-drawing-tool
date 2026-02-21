/// Represents an audio recording attached to a document.
///
/// Audio recordings are document-level (not page-level), but each recording
/// tracks the [pageIndex] where it was initiated. Duration and filePath
/// are placeholder values until the real recording backend is implemented.
class AudioRecording {
  final String id;
  final String title;
  final String filePath;
  final Duration duration;
  final int pageIndex;
  final DateTime createdAt;

  const AudioRecording({
    required this.id,
    required this.title,
    this.filePath = '',
    this.duration = Duration.zero,
    required this.pageIndex,
    required this.createdAt,
  });

  /// Creates a new recording with a generated ID and current timestamp.
  factory AudioRecording.create({
    required String title,
    required int pageIndex,
  }) {
    return AudioRecording(
      id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      pageIndex: pageIndex,
      createdAt: DateTime.now(),
    );
  }

  AudioRecording copyWith({
    String? title,
    String? filePath,
    Duration? duration,
    int? pageIndex,
  }) {
    return AudioRecording(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      pageIndex: pageIndex ?? this.pageIndex,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'durationMs': duration.inMilliseconds,
        'pageIndex': pageIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AudioRecording.fromJson(Map<String, dynamic> json) {
    return AudioRecording(
      id: json['id'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String? ?? '',
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      pageIndex: json['pageIndex'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioRecording &&
        other.id == id &&
        other.title == title &&
        other.filePath == filePath &&
        other.duration == duration &&
        other.pageIndex == pageIndex &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, filePath, duration, pageIndex, createdAt);
}
