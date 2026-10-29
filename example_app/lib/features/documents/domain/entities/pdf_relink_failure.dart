import 'package:example_app/core/core.dart';

/// Why re-linking a missing source PDF failed.
enum PdfRelinkError {
  openFailed,
  passwordProtected,
  fileAccess,
  storageFull,

  /// The picked PDF has fewer pages than the notebook references.
  pageCountMismatch,

  /// A file already exists at the stored path; it is never overwritten.
  targetExists,
}

/// A typed re-link failure. The presentation layer maps [error] to copy;
/// [found] and [required] are only set for [PdfRelinkError.pageCountMismatch].
class PdfRelinkFailure extends Failure {
  const PdfRelinkFailure(this.error, {this.found = 0, this.required = 0})
      : super('PDF re-link failed', code: 'pdf_relink');

  final PdfRelinkError error;
  final int found;
  final int required;

  @override
  List<Object?> get props => [message, code, error, found, required];
}
