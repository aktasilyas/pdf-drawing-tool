/// Something the platform reported about a PDF handed to the app by another
/// app (Open with / Share): either the PDF itself or why it could not be read.
sealed class IncomingPdfEvent {
  const IncomingPdfEvent();
}

/// A PDF handed to the app by another app (Open with / Share).
///
/// [path] points to a private cache copy that the consumer must delete once
/// the PDF has been imported.
class IncomingPdf extends IncomingPdfEvent {
  const IncomingPdf({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;

  @override
  bool operator ==(Object other) =>
      other is IncomingPdf &&
      other.path == path &&
      other.name == name &&
      other.size == size;

  @override
  int get hashCode => Object.hash(path, name, size);

  @override
  String toString() => 'IncomingPdf($name, $size bytes, $path)';
}

/// Why a handed-over PDF could not be copied into the app.
enum IncomingPdfFailureReason {
  /// The device ran out of storage while copying.
  storageFull,

  /// The stream could not be opened or read (revoked permission, broken
  /// provider, I/O error).
  unreadable,
}

/// A PDF handed to the app that could not be copied; nothing was imported.
class IncomingPdfFailure extends IncomingPdfEvent {
  const IncomingPdfFailure({required this.name, required this.reason});

  /// File name as reported by the sending app.
  final String name;
  final IncomingPdfFailureReason reason;

  @override
  bool operator ==(Object other) =>
      other is IncomingPdfFailure &&
      other.name == name &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(name, reason);

  @override
  String toString() => 'IncomingPdfFailure($name, ${reason.name})';
}
