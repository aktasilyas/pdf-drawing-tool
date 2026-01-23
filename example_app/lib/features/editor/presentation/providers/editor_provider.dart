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

// Document loading state
final documentLoaderProvider = FutureProvider.family<DrawingDocument, String>((ref, documentId) async {
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

class AutoSaveNotifier extends StateNotifier<bool> {
  final Ref _ref;
  Timer? _debounceTimer;
  
  AutoSaveNotifier(this._ref) : super(false);

  void documentChanged(DrawingDocument document) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      _save(document);
    });
  }

  Future<void> _save(DrawingDocument document) async {
    state = true; // Saving...
    final useCase = _ref.read(saveDocumentUseCaseProvider);
    await useCase(document);
    state = false; // Saved
    _ref.read(hasUnsavedChangesProvider.notifier).state = false;
  }

  void saveNow(DrawingDocument document) {
    _debounceTimer?.cancel();
    _save(document);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Has unsaved changes
final hasUnsavedChangesProvider = StateProvider<bool>((ref) => false);
