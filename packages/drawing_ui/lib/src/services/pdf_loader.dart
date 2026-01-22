import 'dart:io';
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';
import 'package:drawing_ui/src/models/pdf_info.dart';

/// Exception thrown when PDF loading or processing fails.
class PDFLoaderException implements Exception {
  /// Error message.
  final String message;

  /// Original cause (if any).
  final Object? cause;

  const PDFLoaderException(this.message, {this.cause});

  @override
  String toString() {
    if (cause != null) {
      return 'PDFLoaderException: $message\nCaused by: $cause';
    }
    return 'PDFLoaderException: $message';
  }
}

/// Service for loading and inspecting PDF documents.
///
/// Provides methods to load PDFs from file or bytes, extract metadata,
/// and manage document lifecycle.
class PDFLoader {
  /// Loaded documents cache.
  final List<PdfDocument> _loadedDocuments = [];

  /// Whether this loader has been disposed.
  bool _isDisposed = false;

  /// Whether this loader has been disposed.
  bool get isDisposed => _isDisposed;

  /// Number of currently loaded documents.
  int get loadedDocumentCount => _loadedDocuments.length;

  /// Loads a PDF document from a file path.
  ///
  /// Throws [PDFLoaderException] if the file doesn't exist, is not a valid PDF,
  /// or if the loader has been disposed.
  Future<PdfDocument> loadFromFile(String path) async {
    _checkNotDisposed();

    try {
      // Check if file exists
      final file = File(path);
      if (!await file.exists()) {
        throw PDFLoaderException('File not found: $path');
      }

      // Load PDF document
      final document = await PdfDocument.openFile(path);
      _loadedDocuments.add(document);
      
      return document;
    } catch (e) {
      if (e is PDFLoaderException) rethrow;
      throw PDFLoaderException('Failed to load PDF from file: $path', cause: e);
    }
  }

  /// Loads a PDF document from bytes.
  ///
  /// Throws [PDFLoaderException] if the bytes are not a valid PDF
  /// or if the loader has been disposed.
  Future<PdfDocument> loadFromBytes(Uint8List bytes) async {
    _checkNotDisposed();

    if (bytes.isEmpty) {
      throw PDFLoaderException('PDF bytes are empty');
    }

    try {
      // Load PDF document from bytes
      final document = await PdfDocument.openData(bytes);
      _loadedDocuments.add(document);
      
      return document;
    } catch (e) {
      throw PDFLoaderException('Failed to load PDF from bytes', cause: e);
    }
  }

  /// Extracts document information from a PDF.
  ///
  /// Returns [PDFInfo] with metadata if available.
  Future<PDFInfo> getDocumentInfo(PdfDocument document) async {
    _checkNotDisposed();

    try {
      final pageCount = document.pagesCount;

      // Extract metadata if available
      // Note: pdfx doesn't provide direct metadata access in current version
      // We return minimal info with page count
      return PDFInfo.minimal(pageCount);
    } catch (e) {
      throw PDFLoaderException('Failed to extract document info', cause: e);
    }
  }

  /// Gets the page count of a document.
  Future<int> getPageCount(PdfDocument document) async {
    _checkNotDisposed();

    try {
      return document.pagesCount;
    } catch (e) {
      throw PDFLoaderException('Failed to get page count', cause: e);
    }
  }

  /// Disposes a specific document.
  Future<void> disposeDocument(PdfDocument document) async {
    try {
      await document.close();
      _loadedDocuments.remove(document);
    } catch (e) {
      // Ignore disposal errors
    }
  }

  /// Disposes all loaded documents and cleans up resources.
  void dispose() {
    if (_isDisposed) return;

    // Close all loaded documents
    for (final document in _loadedDocuments) {
      try {
        document.close();
      } catch (e) {
        // Ignore disposal errors
      }
    }

    _loadedDocuments.clear();
    _isDisposed = true;
  }

  /// Checks if the loader has been disposed and throws if it has.
  void _checkNotDisposed() {
    if (_isDisposed) {
      throw PDFLoaderException('PDFLoader has been disposed');
    }
  }
}
