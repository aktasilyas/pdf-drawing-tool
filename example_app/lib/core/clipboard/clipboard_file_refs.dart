/// Stored file paths the editor clipboards (copied page, copied selection)
/// still reference. The cleanup of managed files consults it so a file is not
/// deleted while a paste could still need it.
///
/// The editor side (`clipboardFileRefsProvider`) is bound to [paths] at the
/// app root; until then the clipboard counts as empty.
class ClipboardFileRefs {
  /// Supplies the currently referenced stored paths.
  Set<String> Function() paths = _none;

  /// Whether [path] is referenced by a clipboard right now.
  bool contains(String path) => paths().contains(path);

  static Set<String> _none() => const {};
}
