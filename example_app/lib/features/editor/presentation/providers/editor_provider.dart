import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/editor/domain/usecases/load_document_usecase.dart';
import 'package:example_app/features/editor/domain/usecases/save_document_usecase.dart';

// Provider for LoadDocumentUseCase
final loadDocumentUseCaseProvider = Provider<LoadDocumentUseCase>((ref) {
  return getIt<LoadDocumentUseCase>();
});

// Provider for SaveDocumentUseCase
final saveDocumentUseCaseProvider = Provider<SaveDocumentUseCase>((ref) {
  return getIt<SaveDocumentUseCase>();
});

// Current document being edited
final currentDocumentProvider = StateProvider<DrawingDocument?>((ref) => null);

// Document loading state (autoDispose prevents stale cache on re-entry)
final documentLoaderProvider = FutureProvider.autoDispose
    .family<DrawingDocument, String>((ref, documentId) async {
  final useCase = ref.watch(loadDocumentUseCaseProvider);
  final result = await useCase(documentId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (document) => document,
  );
});

// Auto-save controller
final autoSaveProvider = StateNotifierProvider<AutoSaveNotifier, bool>((ref) {
  return AutoSaveNotifier(ref);
});

// Latest failed save; null when the last save succeeded. The editor shows a
// persistent "Kaydedilemedi" banner with Retry while this is set.
final saveFailureProvider = StateProvider<Failure?>((ref) => null);

class AutoSaveNotifier extends StateNotifier<bool> {
  final Ref _ref;
  Timer? _debounceTimer;
  DrawingDocument? _pending;

  /// Delay between the last change and the automatic save.
  static const debounce = Duration(seconds: 3);

  /// Newest document handed to this notifier; what [retry] saves.
  DrawingDocument? _latest;

  AutoSaveNotifier(this._ref) : super(false);

  /// Whether a change is waiting for the debounce timer.
  bool get hasPendingSave => _pending != null;

  void documentChanged(DrawingDocument document) {
    _latest = document;
    _debounceTimer?.cancel();
    _pending = document;
    _debounceTimer = Timer(debounce, () {
      _pending = null;
      _save(document);
    });
  }

  /// Saves a pending change right away (app paused, back pressed).
  /// Does nothing when there is no pending change.
  Future<void> flush() {
    final pending = _pending;
    if (pending == null) return Future<void>.value();
    return saveNow(pending);
  }

  Future<void> _save(DrawingDocument document) async {
    state = true; // Saving...
    final useCase = _ref.read(saveDocumentUseCaseProvider);
    final result = await useCase(document);

    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      logger.e('Save failed', error: failure.message);
    } else {
      logger.i('Document saved successfully: ${document.id}');
    }

    // A lifecycle flush can outlive the editor (provider invalidated on leave).
    if (!mounted) return;
    _ref.read(saveFailureProvider.notifier).state = failure;
    state = false; // Saved
    // A failed save keeps the unsaved flag so nothing is reported as saved.
    if (failure != null) return;
    // Only clear unsaved flag if no new changes arrived during save
    if (_debounceTimer == null || !_debounceTimer!.isActive) {
      _ref.read(hasUnsavedChangesProvider.notifier).state = false;
    }
  }

  /// Saves the newest document again after a failed save.
  Future<void> retry() {
    final latest = _latest;
    if (latest == null) return Future<void>.value();
    return saveNow(latest);
  }

  Future<void> saveNow(DrawingDocument document) {
    _latest = document;
    _debounceTimer?.cancel();
    _pending = null;
    return _save(document);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Has unsaved changes
final hasUnsavedChangesProvider = StateProvider<bool>((ref) => false);
