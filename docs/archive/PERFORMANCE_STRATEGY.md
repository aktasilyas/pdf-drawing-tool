# Performance Strategy Document

## Executive Summary

This document outlines the performance architecture for a high-performance Flutter drawing engine. The primary goals are:

1. **Smooth drawing** - No perceptible lag during stroke input
2. **Efficient undo/redo** - O(1) operations, minimal memory overhead
3. **Scalable documents** - Handle 10,000+ strokes without degradation
4. **Responsive zoom/pan** - Fluid navigation at any scale
5. **Non-blocking AI operations** - AI features must not impact drawing performance

---

## Current Best Practices for Flutter Canvas Performance

### 1. CustomPainter Optimization

#### Repaint Minimization

```dart
class OptimizedPainter extends CustomPainter {
  // Use shouldRepaint wisely
  @override
  bool shouldRepaint(covariant OptimizedPainter oldDelegate) {
    // Only repaint if data actually changed
    return oldDelegate.strokes != strokes || 
           oldDelegate.activeStroke != activeStroke;
  }
}
```

**Key principles**:
- `shouldRepaint` should be as cheap as possible (identity checks preferred)
- Separate static content from dynamic content into different painters
- Use `RepaintBoundary` strategically (see below)

#### Avoid Common Pitfalls

| Pitfall | Impact | Solution |
|---------|--------|----------|
| Creating Paint objects in `paint()` | GC pressure | Cache Paint objects |
| Complex path operations every frame | CPU spike | Pre-compute, cache paths |
| Large number of draw calls | Draw call overhead | Batch similar operations |
| Allocations in paint loop | GC pauses | Pool objects, reuse lists |

### 2. PictureRecorder → Image Caching

The most effective optimization for drawing apps:

```dart
// Record strokes to a Picture
final recorder = ui.PictureRecorder();
final canvas = Canvas(recorder);

// Draw all committed strokes
for (final stroke in committedStrokes) {
  paintStroke(canvas, stroke);
}

final picture = recorder.endRecording();

// Convert to raster image for fast blitting
final image = await picture.toImage(width, height);

// In paint(), just draw the cached image
canvas.drawImage(cachedImage, Offset.zero, Paint());
```

**When to use**:
- Committed (finished) strokes → cached as image
- Active stroke (being drawn) → rendered live on top
- On stroke completion → re-bake cache incrementally

### 3. RepaintBoundary Strategy

```dart
Stack(
  children: [
    // Static layers - isolated repaint
    RepaintBoundary(
      child: CustomPaint(
        painter: BackgroundPainter(),
      ),
    ),
    // Dynamic canvas - separate repaint
    RepaintBoundary(
      child: CustomPaint(
        painter: StrokePainter(strokes),
      ),
    ),
    // UI overlay - yet another boundary
    RepaintBoundary(
      child: ToolbarOverlay(),
    ),
  ],
)
```

**Guidelines**:
- Don't overuse - each boundary has memory cost
- Use when content repaints at different frequencies
- Profile with `debugRepaintRainbowEnabled`

### 4. Avoiding setState Storms

```dart
// BAD: Triggers rebuild + repaint on every point
onPointerMove: (event) {
  setState(() {
    currentStroke.points.add(event.localPosition);
  });
}

// GOOD: Use ValueNotifier or direct CustomPainter notification
class StrokeNotifier extends ChangeNotifier {
  void addPoint(Offset point) {
    _currentStroke.points.add(point);
    notifyListeners(); // Only repaints CustomPaint, not whole widget tree
  }
}

CustomPaint(
  painter: StrokePainter(strokeNotifier),
  // repaint triggers only when notifier fires
)
```

### 5. Pointer Event Handling

```dart
Listener(
  // Use Listener, not GestureDetector for raw pointer data
  onPointerDown: _handlePointerDown,
  onPointerMove: _handlePointerMove,
  onPointerUp: _handlePointerUp,
)

void _handlePointerMove(PointerMoveEvent event) {
  // Access coalesced events for high-frequency input
  for (final historical in event.original?.historyEntries ?? []) {
    _addPoint(historical.localPosition, historical.pressure);
  }
  _addPoint(event.localPosition, event.pressure);
}
```

---

## Known Pitfalls & Solutions

### 1. Many Complex Paths Each Frame

**Problem**: Drawing 1000s of strokes as individual Path objects.

**Solution**: 
- Bake completed strokes to cached image
- Only render active stroke as live path
- Use stroke segmentation (see below)

### 2. Zoom/Pan Performance Issues

**Problem**: Re-rendering entire canvas on every transform change.

**Solutions**:
- Use `Transform` widget with cached child (not CustomPainter transform)
- Implement viewport culling (only render visible strokes)
- Consider tile-based rendering for very large canvases
- Cache at multiple zoom levels (LOD)

### 3. Overlayed Painters Latency

**Problem**: Multiple stacked CustomPaint widgets causing layered repaints.

**Solution**:
- Consolidate painters where possible
- Use single CustomPainter with internal layer management
- Profile to identify actual bottleneck

### 4. Memory Pressure from History

**Problem**: Storing complete state for every undo step.

**Solution**: Command pattern (see Undo/Redo section below)

---

## Proposed Strategy for Our Engine

### 1. Stroke Segmentation

Divide long strokes into segments for efficient:
- Hit testing (eraser)
- Partial rendering (viewport culling)
- Incremental caching

```dart
class Stroke {
  final List<StrokeSegment> segments;
  
  // Each segment is ~50-100 points
  // Has its own bounding box for fast culling
  // Can be cached individually
}

class StrokeSegment {
  final List<DrawingPoint> points;
  final Rect boundingBox;
  ui.Image? cachedImage; // Optional per-segment cache
}
```

### 2. Incremental Raster Cache

```
┌─────────────────────────────────────────────────────────┐
│                    Rendering Pipeline                    │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 0: Background                                     │
│  - Cached as single image                                │
│  - Re-cached only on background change                   │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 1-N: Stroke Layers                                │
│  ┌─────────────────────────────────────────────────────┐│
│  │  Committed Strokes (baked)                          ││
│  │  - Cached as single image per layer                 ││
│  │  - Re-baked every N strokes or on idle              ││
│  └─────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────┐│
│  │  Recent Strokes (unbaked)                           ││
│  │  - Rendered as paths (max ~10 strokes)              ││
│  │  - Merged into cache when count exceeds threshold   ││
│  └─────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────┐│
│  │  Active Stroke                                       ││
│  │  - Always rendered live                              ││
│  │  - Moves to "recent" on pointer up                   ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│  Compositing                                             │
│  - Stack cached images + live paths                      │
│  - Apply zoom/pan transform                              │
│  - Draw to screen                                        │
└─────────────────────────────────────────────────────────┘
```

### 3. Layer Merging on Idle

```dart
class CacheManager {
  static const int _bakeThreshold = 10;
  static const Duration _idleDelay = Duration(milliseconds: 500);
  
  Timer? _idleTimer;
  
  void onStrokeAdded() {
    _idleTimer?.cancel();
    
    if (_recentStrokes.length > _bakeThreshold) {
      _bakeRecentStrokes();
    } else {
      // Schedule idle bake
      _idleTimer = Timer(_idleDelay, _bakeRecentStrokes);
    }
  }
  
  void _bakeRecentStrokes() {
    // Move recent strokes to cached image
    // This runs when user pauses drawing
  }
}
```

### 4. Pointer Event Throttling

```dart
class ThrottledPointerHandler {
  static const Duration _minInterval = Duration(milliseconds: 8); // ~120fps
  DateTime _lastProcessed = DateTime.now();
  final List<DrawingPoint> _pendingPoints = [];
  
  void onPointerMove(PointerMoveEvent event) {
    // Collect all points
    _pendingPoints.add(DrawingPoint.fromEvent(event));
    
    final now = DateTime.now();
    if (now.difference(_lastProcessed) > _minInterval) {
      _flushPoints();
      _lastProcessed = now;
    }
  }
  
  void _flushPoints() {
    // Process batch of points
    // Apply smoothing
    // Update canvas
  }
}
```

### 5. Isolate UI from Canvas Repaints

```dart
// Architecture
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Canvas layer - repaints frequently during drawing
      RepaintBoundary(
        key: _canvasKey,
        child: DrawingCanvas(
          controller: _drawingController,
        ),
      ),
      // UI layer - repaints only on tool/panel changes
      RepaintBoundary(
        key: _uiKey,
        child: ToolbarOverlay(
          // UI widgets
        ),
      ),
    ],
  );
}
```

---

## Undo/Redo Efficiency

### Command Pattern Implementation

```dart
abstract class DrawingCommand {
  void execute(DrawingDocument document);
  void undo(DrawingDocument document);
  
  // Optional: memory estimation for pruning
  int get estimatedMemoryBytes;
}

class AddStrokeCommand extends DrawingCommand {
  final Stroke stroke;
  final int layerIndex;
  
  @override
  void execute(DrawingDocument document) {
    document.layers[layerIndex].strokes.add(stroke);
  }
  
  @override
  void undo(DrawingDocument document) {
    document.layers[layerIndex].strokes.removeLast();
  }
}

class RemoveStrokeCommand extends DrawingCommand {
  final Stroke stroke;
  final int layerIndex;
  final int strokeIndex;
  
  @override
  void execute(DrawingDocument document) {
    document.layers[layerIndex].strokes.removeAt(strokeIndex);
  }
  
  @override
  void undo(DrawingDocument document) {
    document.layers[layerIndex].strokes.insert(strokeIndex, stroke);
  }
}
```

### History Stack with Snapshots

```dart
class HistoryManager {
  final List<DrawingCommand> _undoStack = [];
  final List<DrawingCommand> _redoStack = [];
  final List<DocumentSnapshot> _snapshots = [];
  
  static const int _maxHistorySize = 100;
  static const int _snapshotInterval = 20;
  
  void push(DrawingCommand command) {
    command.execute(_document);
    _undoStack.add(command);
    _redoStack.clear();
    
    // Create snapshot at intervals for fast random access
    if (_undoStack.length % _snapshotInterval == 0) {
      _snapshots.add(DocumentSnapshot.from(_document));
    }
    
    // Prune old history
    _pruneIfNeeded();
  }
  
  void undo() {
    if (_undoStack.isEmpty) return;
    
    final command = _undoStack.removeLast();
    command.undo(_document);
    _redoStack.add(command);
    
    // Invalidate cache for affected layer
    _invalidateCache(command);
  }
  
  void redo() {
    if (_redoStack.isEmpty) return;
    
    final command = _redoStack.removeLast();
    command.execute(_document);
    _undoStack.add(command);
    
    _invalidateCache(command);
  }
}
```

### Memory-Efficient Snapshots

```dart
class DocumentSnapshot {
  final int commandIndex;
  final ui.Image? rasterSnapshot; // Optional full raster
  final Map<int, int> layerStrokeCounts; // Lightweight state reference
  
  // Only store full raster every N snapshots
  // Otherwise, can rebuild from nearest snapshot + commands
}
```

---

## ⭐ AI-Triggered Operations Performance (App Layer)

> **CRITICAL**: All AI operations MUST be non-blocking. Users must be able to continue drawing while AI processes in the background.

### Performance Principles

1. **Never block the UI thread** for AI operations
2. **Use isolates** for heavy data preparation
3. **Debounce** rapid AI requests
4. **Cache** responses aggressively
5. **Stream** responses for perceived performance
6. **Graceful degradation** on timeout or error

### Architecture for Non-Blocking AI

```
┌─────────────────────────────────────────────────────────────┐
│                      Main Isolate (UI)                       │
│  ┌─────────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │  Drawing Canvas │  │  AI Button   │  │  AI Panel      │  │
│  │  (unaffected)   │  │  (triggers)  │  │  (displays)    │  │
│  └─────────────────┘  └──────┬───────┘  └───────▲────────┘  │
│                              │                   │           │
└──────────────────────────────┼───────────────────┼───────────┘
                               │                   │
                               ▼                   │
┌──────────────────────────────────────────────────┼───────────┐
│               Background Processing               │           │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────┴────────┐  │
│  │  Isolate:       │  │  Debouncer   │  │  Response      │  │
│  │  Context Build  │  │  (300ms)     │  │  Stream        │  │
│  └────────┬────────┘  └──────────────┘  └────────────────┘  │
│           │                                                  │
│           ▼                                                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              AI Request Queue                            ││
│  │  - Max 1 concurrent request                              ││
│  │  - Cancel outdated requests                              ││
│  │  - Timeout: 30s                                          ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    External AI API                           │
│                  (OpenAI, Anthropic, etc.)                   │
└─────────────────────────────────────────────────────────────┘
```

### Context Preparation in Isolate

Heavy operations like rasterization MUST run in isolates:

```dart
// In example_app - App layer only

class AIContextPreparer {
  /// Prepare AI context in background isolate.
  /// Returns quickly with a Future - doesn't block UI.
  Future<AIContext> prepareContext(SelectionContext selection) async {
    // Spawn isolate for heavy work
    return await Isolate.run(() {
      // This runs in background isolate
      final textExtractor = TextExtractor();
      final texts = textExtractor.extractFromSelection(selection);
      
      // Rasterize selection (CPU intensive)
      final rasterizer = RegionRasterizer();
      final imageBytes = rasterizer.rasterizeSelectionSync(
        selection,
        maxDimension: 1024,
      );
      
      return AIContext(
        extractedTexts: texts,
        imageBase64: base64Encode(imageBytes),
        timestamp: DateTime.now(),
      );
    });
  }
}
```

### Request Debouncing

Prevent spam when user rapidly changes selection:

```dart
class DebouncedAIService {
  Timer? _debounceTimer;
  static const _debounceDelay = Duration(milliseconds: 300);
  
  CancelableOperation<AIResponse>? _pendingRequest;
  
  Future<AIResponse> askWithDebounce(
    SelectionContext selection,
    String question,
  ) async {
    // Cancel any pending request
    _pendingRequest?.cancel();
    _debounceTimer?.cancel();
    
    // Wait for debounce period
    final completer = Completer<AIResponse>();
    
    _debounceTimer = Timer(_debounceDelay, () async {
      try {
        _pendingRequest = CancelableOperation.fromFuture(
          _actualAICall(selection, question),
        );
        final response = await _pendingRequest!.value;
        completer.complete(response);
      } catch (e) {
        completer.completeError(e);
      }
    });
    
    return completer.future;
  }
}
```

### Response Streaming

For perceived performance, stream AI responses:

```dart
class StreamingAIPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiService = ref.watch(aiServiceProvider);
    
    return StreamBuilder<String>(
      stream: aiService.streamResponse(prompt),
      builder: (context, snapshot) {
        // Show partial response as it arrives
        return AnimatedText(
          text: snapshot.data ?? '',
          isComplete: snapshot.connectionState == ConnectionState.done,
        );
      },
    );
  }
}
```

### Response Caching

Cache AI responses by content hash:

```dart
class CachedAIService implements AIAssistantService {
  final AIAssistantService _delegate;
  final Map<String, AIResponse> _cache = {};
  
  static const _maxCacheSize = 50;
  static const _cacheTTL = Duration(hours: 1);
  
  @override
  Future<AIResponse> askAboutSelection(
    SelectionContext selection,
    String question,
  ) async {
    // Generate cache key from selection content + question
    final cacheKey = '${selection.contentHash}:${question.hashCode}';
    
    // Check cache
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    
    // Fetch and cache
    final response = await _delegate.askAboutSelection(selection, question);
    _cache[cacheKey] = response;
    _pruneCache();
    
    return response;
  }
}
```

### Timeout and Retry Strategy

```dart
class ResilientAIService {
  static const _timeout = Duration(seconds: 30);
  static const _maxRetries = 2;
  static const _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];
  
  Future<AIResponse> askWithRetry(
    SelectionContext selection,
    String question,
  ) async {
    Exception? lastError;
    
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await _makeRequest(selection, question)
            .timeout(_timeout);
      } on TimeoutException {
        lastError = TimeoutException('AI request timed out');
        // Don't retry timeouts
        break;
      } on NetworkException catch (e) {
        lastError = e;
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelays[attempt]);
        }
      }
    }
    
    // Return graceful error response
    return AIResponse.error(
      'Unable to get AI response. Please try again.',
      cause: lastError,
    );
  }
}
```

### Progress Indication

Show progress without blocking interaction:

```dart
class AIProgressIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiStateProvider);
    
    return switch (aiState) {
      AIStateIdle() => const SizedBox.shrink(),
      AIStatePreparing() => const LinearProgressIndicator(
          value: null, // Indeterminate while preparing context
        ),
      AIStateWaiting(progress: final p) => LinearProgressIndicator(
          value: p, // Show actual progress if available
        ),
      AIStateStreaming(partialResponse: final r) => Column(
          children: [
            const LinearProgressIndicator(value: null),
            Text(r), // Show partial response
          ],
        ),
      AIStateComplete() => const Icon(Icons.check),
      AIStateError(message: final m) => ErrorWidget(message: m),
    };
  }
}
```

### Performance Budgets for AI Operations

| Operation | Target | Maximum |
|-----------|--------|---------|
| Selection → Context build (isolate) | < 100ms | 200ms |
| Rasterization (1024px) | < 150ms | 300ms |
| API round-trip (network) | < 2s | 30s (timeout) |
| Response stream first byte | < 500ms | 2s |
| Cache lookup | < 5ms | 10ms |
| UI remains responsive | Always | Always |

### What NOT to Do

❌ Don't rasterize on main thread  
❌ Don't block UI while waiting for AI response  
❌ Don't send request on every selection change (debounce!)  
❌ Don't keep stale requests running (cancel them)  
❌ Don't show empty state while streaming (show partial)  
❌ Don't retry indefinitely (max 2 retries)  

---

## Benchmarking Targets

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Input latency | < 16ms | Stopwatch from pointer event to paint |
| Frame time (drawing) | < 8ms | DevTools timeline |
| Frame time (idle) | < 2ms | DevTools timeline |
| Undo operation | < 5ms | Stopwatch |
| Memory per stroke | < 1KB avg | Heap snapshot analysis |
| Document load (1000 strokes) | < 500ms | Stopwatch |
| Cache bake time | < 50ms | Stopwatch |
| AI context preparation | < 100ms | Stopwatch (isolate) |
| Selection rasterization | < 200ms | Stopwatch (isolate) |

---

## Profiling Checklist

- [ ] Enable `debugProfilePaintsEnabled`
- [ ] Use DevTools Performance view
- [ ] Profile on release build (not debug)
- [ ] Test on low-end device (not just simulator)
- [ ] Monitor memory with DevTools Memory view
- [ ] Check for jank during rapid drawing
- [ ] Check for jank during undo/redo
- [ ] Check for jank during zoom/pan
- [ ] Verify no memory leaks (repeated create/dispose)
- [ ] **NEW: Verify drawing remains smooth during AI operations**
- [ ] **NEW: Profile AI context preparation time**
- [ ] **NEW: Verify AI response caching works**

---

## Implementation Phases

### Phase 2 (Drawing Core v1)
- Basic stroke rendering with CustomPainter
- Simple undo/redo with command pattern
- No caching yet (establish baseline)
- SelectionContext model (data only)

### Phase 3 (Advanced Tools + AI Prep)
- Selection system with context building
- Content extraction utilities
- Region rasterization (for AI/export)
- All operations must remain non-blocking

### Phase 4 (Performance Hardening)
- Implement incremental raster cache
- Add stroke segmentation
- Implement idle-time baking
- Add pointer event throttling
- Profile and tune thresholds
- **AI operation performance optimization**
- **Isolate-based context preparation**
- **Response caching implementation**

### Future Optimization
- Tile-based rendering (if needed for very large canvases)
- GPU compute for path operations (if available)
- Isolate-based background processing
- AI response pre-fetching for common queries

---

## References

- [Flutter CustomPainter documentation](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [Optimizing Performance in Flutter](https://docs.flutter.dev/perf/best-practices)
- [RepaintBoundary documentation](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
- [PictureRecorder documentation](https://api.flutter.dev/flutter/dart-ui/PictureRecorder-class.html)
- [Dart Isolates](https://dart.dev/language/concurrency)

---

## TODO: Research & Validation

- [ ] Benchmark `toImage()` performance on various devices
- [ ] Test optimal snapshot interval (10? 20? 50?)
- [ ] Measure memory impact of cached images
- [ ] Compare Path vs recorded Picture for stroke storage
- [ ] Test Impeller vs Skia rendering differences
- [ ] Evaluate `flutter_processing` or similar libraries for reference
- [ ] **NEW: Benchmark isolate spawn overhead vs compute.run**
- [ ] **NEW: Test AI context preparation on low-end devices**
- [ ] **NEW: Measure network latency impact on UX**
- [ ] **NEW: Evaluate streaming API performance**
