# Phase 5: Multi-Page & PDF System - Edge Cases & Error Handling

## 🛡️ Edge Cases Handled

### 1. Document Edge Cases

#### Empty Documents
```dart
// ✅ Handled: Always have at least one page
final doc = DrawingDocument.multiPage(
  id: 'd1',
  title: 'Empty Doc',
  pages: [], // Will auto-create one empty page
);

// PageManager prevents deleting last page
manager.deletePage(0); // Throws StateError
```

#### Invalid Dimensions
```dart
// ✅ Handled: Validate page dimensions
final page = Page(
  size: PageSize(width: -1, height: -1), // Invalid
  // ...
);

final exporter = PDFExporter();
exporter.isPageExportable(page); // Returns false
```

#### Corrupted JSON
```dart
// ✅ Handled: Graceful error handling
try {
  final doc = DrawingDocument.fromJson(corruptedJson);
} catch (e) {
  // Show user-friendly error
  showError('Failed to load document: Invalid format');
}
```

---

### 2. Page Management Edge Cases

#### Page Index Boundaries
```dart
// ✅ Handled: Range validation
manager.goToPage(-1); // Throws RangeError
manager.goToPage(manager.pageCount); // Throws RangeError

// ✅ Safe navigation
if (manager.canGoNext) {
  manager.nextPage();
}
```

#### Rapid Page Switching
```dart
// ✅ Handled: Cancel previous load
Future<void> _switchPage(int index) async {
  // Cancel ongoing load
  _currentLoadCancellation?.cancel();
  
  // Start new load
  _currentLoadCancellation = CancellationToken();
  await _loadPage(index, _currentLoadCancellation);
}
```

#### Concurrent Modifications
```dart
// ✅ Handled: Immutable pages
final page = Page.create(index: 0);
final updatedPage = page.addStroke(stroke); // Returns new page

// Original page unchanged
expect(page.layers.first.strokes, isEmpty);
expect(updatedPage.layers.first.strokes.length, 1);
```

---

### 3. Memory Edge Cases

#### Memory Exhaustion
```dart
// ✅ Handled: Budget enforcement
if (!memoryBudget.canAllocate(requiredSize)) {
  // Evict oldest pages
  _evictOldestPages(requiredSize);
  
  if (!memoryBudget.canAllocate(requiredSize)) {
    // Still can't allocate - downscale
    final downscaledSize = requiredSize / 2;
    memoryBudget.allocate(key, downscaledSize);
  }
}
```

#### Memory Leaks
```dart
// ✅ Handled: Proper disposal
class MyWidget extends StatefulWidget {
  @override
  void dispose() {
    // Always dispose services
    pageManager.dispose();
    thumbnailCache.clear();
    importService.dispose();
    exportService.dispose();
    super.dispose();
  }
}
```

#### Cache Overflow
```dart
// ✅ Handled: LRU eviction
thumbnailCache.put(key, data); // Auto-evicts if full

// Manual eviction if needed
if (thumbnailCache.isFull) {
  thumbnailCache.evictLRU();
}
```

---

### 4. PDF Import Edge Cases

#### Invalid PDF Files
```dart
// ✅ Handled: File validation
try {
  final document = await pdfLoader.loadFromFile(path);
} catch (e) {
  if (e is PDFLoaderException) {
    showError('Invalid PDF file: ${e.message}');
  }
}
```

#### Corrupted PDF
```dart
// ✅ Handled: Error recovery
final result = await importService.importFromFile(
  filePath: path,
  config: config,
);

if (!result.isSuccess) {
  showError('Import failed: ${result.errorMessage}');
  // Offer retry or file selection
}
```

#### Empty PDF
```dart
// ✅ Handled: Page count validation
final info = await pdfLoader.getDocumentInfo(document);

if (info.pageCount == 0) {
  showError('PDF has no pages');
  return;
}
```

#### Very Large PDF
```dart
// ✅ Handled: Batch processing
final batchSize = importService.calculateOptimalBatchSize(
  totalPages: pdfDocument.pagesCount,
  availableMemory: memoryBudget.availableBytes,
);

// Process in batches
for (int i = 0; i < pdfDocument.pagesCount; i += batchSize) {
  await _importBatch(i, min(i + batchSize, pdfDocument.pagesCount));
}
```

#### Out of Range Pages
```dart
// ✅ Handled: Page number validation
final config = PDFImportConfig.pageRange(
  startPage: 1,
  endPage: 100, // PDF only has 50 pages
);

if (!config.isValid(totalPages: pdfInfo.pageCount)) {
  showError('Selected range exceeds PDF page count');
}
```

---

### 5. PDF Export Edge Cases

#### Empty Pages
```dart
// ✅ Handled: Exportable check
final emptyPage = Page.create(index: 0);

if (exporter.isPageExportable(emptyPage)) {
  // Export with background only
  await exporter.exportPage(page: emptyPage, options: options);
}
```

#### Very Complex Content
```dart
// ✅ Handled: Automatic raster fallback
if (rasterRenderer.shouldUseRasterFallback(page)) {
  // Use raster mode
  config = config.copyWith(exportMode: PDFExportMode.raster);
}
```

#### Memory Constraints
```dart
// ✅ Handled: Downscaling
if (!rasterRenderer.canRenderWithMemory(
  page: page,
  dpi: targetDPI,
  availableMemoryBytes: memoryBudget.availableBytes,
)) {
  // Calculate downscale factor
  final scale = rasterRenderer.calculateDownscaleFactor(
    page: page,
    targetDPI: targetDPI,
    availableMemoryBytes: memoryBudget.availableBytes,
  );
  
  // Use scaled DPI
  targetDPI = (targetDPI * scale).round();
}
```

#### Export Cancellation
```dart
// ✅ Handled: Cancellation support
final exportFuture = exportService.exportDocument(
  document: doc,
  config: config,
);

// User cancels
exportService.dispose(); // Stops export

try {
  await exportFuture;
} catch (e) {
  if (e is StateError) {
    // Service was disposed
    showInfo('Export cancelled');
  }
}
```

---

### 6. Thumbnail Edge Cases

#### Missing Thumbnails
```dart
// ✅ Handled: Placeholder display
final thumbnail = thumbnailCache.get(key);

if (thumbnail == null) {
  // Show placeholder
  _showPlaceholder();
  
  // Queue generation
  thumbnailQueue.enqueue(page: page);
}
```

#### Thumbnail Generation Failure
```dart
// ✅ Handled: Graceful fallback
try {
  final thumbnail = await ThumbnailGenerator.generate(page);
  thumbnailCache.put(key, thumbnail);
} catch (e) {
  // Use default thumbnail or icon
  _showDefaultThumbnail();
}
```

#### Queue Overflow
```dart
// ✅ Handled: Priority management
if (thumbnailQueue.pendingTasks.length > maxQueueSize) {
  // Cancel low-priority tasks
  thumbnailQueue.cancelLowPriorityTasks(threshold: 0.3);
}

// Queue with priority
thumbnailQueue.enqueue(page: visiblePage, priority: 1.0);
```

---

### 7. Rendering Edge Cases

#### Zero-Length Strokes
```dart
// ✅ Handled: Stroke validation
if (stroke.points.length < 2) {
  // Skip rendering
  return;
}
```

#### Extreme Coordinates
```dart
// ✅ Handled: Bounds checking
final (pdfX, pdfY) = exporter.convertCoordinates(
  drawingX: point.x,
  drawingY: point.y,
  pageHeight: pageHeight,
);

// Clamp to page bounds
final clampedX = pdfX.clamp(0, pageWidth);
final clampedY = pdfY.clamp(0, pageHeight);
```

#### Invisible Layers
```dart
// ✅ Handled: Visibility check
for (final layer in page.layers) {
  if (!layer.isVisible) continue; // Skip invisible
  
  _renderLayer(canvas, layer);
}
```

---

### 8. Serialization Edge Cases

#### Version Mismatch
```dart
// ✅ Handled: Version detection
factory DrawingDocument.fromJson(Map<String, dynamic> json) {
  final version = json['version'] as int? ?? 1;
  
  if (version == 1) {
    return _fromJsonV1(json); // Legacy format
  }
  
  return _fromJsonV2(json); // Modern format
}
```

#### Missing Fields
```dart
// ✅ Handled: Default values
final width = json['width'] as double? ?? 1920.0;
final height = json['height'] as double? ?? 1080.0;
final layers = (json['layers'] as List?)
    ?.map((e) => Layer.fromJson(e))
    .toList() ?? [];
```

#### Invalid Data Types
```dart
// ✅ Handled: Type checking
try {
  final pages = (json['pages'] as List)
      .map((e) => Page.fromJson(e as Map<String, dynamic>))
      .toList();
} catch (e) {
  throw FormatException('Invalid pages data: $e');
}
```

---

## 🔍 Error Recovery Strategies

### 1. Graceful Degradation
```dart
// Try vector export first
try {
  return await _exportVector(page);
} catch (e) {
  // Fall back to raster
  return await _exportRaster(page);
}
```

### 2. Retry with Backoff
```dart
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      
      await Future.delayed(initialDelay * (i + 1));
    }
  }
  throw Exception('Retry failed');
}
```

### 3. Partial Success
```dart
// Import pages that succeed, report failures
final results = <Page>[];
final errors = <int, String>{};

for (int i = 0; i < pageNumbers.length; i++) {
  try {
    final page = await _importPage(pageNumbers[i]);
    results.add(page);
  } catch (e) {
    errors[pageNumbers[i]] = e.toString();
  }
}

// Show summary
if (errors.isNotEmpty) {
  showWarning('Imported ${results.length}/${pageNumbers.length} pages. '
              '${errors.length} pages failed.');
}
```

---

## ✅ Edge Case Testing

### Test Coverage
- ✅ Empty documents
- ✅ Invalid dimensions  
- ✅ Corrupted JSON
- ✅ Page index boundaries
- ✅ Rapid page switching
- ✅ Memory exhaustion
- ✅ Invalid PDF files
- ✅ Very large PDFs
- ✅ Export cancellation
- ✅ Missing thumbnails
- ✅ Zero-length strokes
- ✅ Version mismatch

### Regression Prevention
- All edge cases have dedicated test cases
- Integration tests cover error scenarios
- Performance tests include stress testing
- Memory leak detection in long-running tests

---

## 📚 Related Documentation
- [PHASE5_MASTER_PLAN.md](./PHASE5_MASTER_PLAN.md)
- [PHASE5_PERFORMANCE.md](./PHASE5_PERFORMANCE.md)
- [Error Handling Guide](../packages/drawing_core/docs/ERROR_HANDLING.md)
