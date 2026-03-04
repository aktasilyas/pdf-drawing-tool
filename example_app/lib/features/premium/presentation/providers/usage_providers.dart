import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Total count of non-trash documents (across all folders).
/// Used by the feature gate to enforce notebook creation limits.
final notebookCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final result = await repository.getDocumentCount();
  return result.fold(
    (failure) => 0,
    (count) => count,
  );
});

/// Count of imported PDF documents (non-trash).
/// Used by the feature gate to enforce PDF import limits.
final pdfImportCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final result =
      await repository.getDocumentCount(documentType: DocumentType.pdf);
  return result.fold(
    (failure) => 0,
    (count) => count,
  );
});
