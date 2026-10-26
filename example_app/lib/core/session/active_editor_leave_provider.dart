import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leaves the mounted editor the same way the Home button does: saves, goes to
/// the library and resets the editor session. Returns false when the save
/// failed and the editor stayed open.
typedef EditorLeave = Future<bool> Function();

/// The leave function of the editor that is currently mounted, or null when
/// no editor is open. Lets other features (e.g. an incoming PDF) close the
/// editor without bypassing its save-and-reset path.
final activeEditorLeaveProvider = StateProvider<EditorLeave?>((ref) => null);
