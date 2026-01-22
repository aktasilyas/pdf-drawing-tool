import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart' hide Page;
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';

/// Represents a thumbnail generation task.
class ThumbnailTask {
  static int _counter = 0;

  /// Unique identifier for this task.
  final String id;

  /// The page to generate a thumbnail for.
  final Page page;

  /// Priority of this task (higher = more important).
  final double priority;

  /// Width of the thumbnail to generate.
  final double width;

  /// Height of the thumbnail to generate.
  final double height;

  /// Background color for the thumbnail.
  final Color backgroundColor;

  /// Creates a thumbnail generation task.
  ThumbnailTask({
    required this.page,
    required this.priority,
    this.width = 150,
    this.height = 200,
    this.backgroundColor = Colors.white,
  }) : id = '${page.id}_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  @override
  String toString() {
    return 'ThumbnailTask(page: ${page.id}, priority: $priority)';
  }
}

/// Manages background thumbnail generation with priority-based processing.
///
/// Provides asynchronous thumbnail generation with:
/// - Priority-based task queue
/// - Concurrent processing with configurable limit
/// - Automatic caching
/// - Task cancellation support
class BackgroundThumbnailQueue {
  /// The thumbnail cache to store generated thumbnails.
  final ThumbnailCache cache;

  /// Maximum number of concurrent thumbnail generation tasks.
  final int maxConcurrent;

  /// Internal queue of pending tasks.
  final List<ThumbnailTask> _queue = [];

  /// Set of currently processing page IDs.
  final Set<String> _processingPageIds = {};

  /// Set of active task futures.
  final Set<Future<void>> _activeTasks = {};

  /// Whether the queue is currently processing tasks.
  bool _isProcessing = false;

  /// Whether the queue has been disposed.
  bool _isDisposed = false;

  /// Callback when a task completes successfully.
  void Function(ThumbnailTask task, Uint8List? data)? onTaskComplete;

  /// Callback when a task fails.
  void Function(ThumbnailTask task, Object error)? onTaskError;

  /// Creates a background thumbnail queue.
  BackgroundThumbnailQueue({
    required this.cache,
    this.maxConcurrent = 2,
  });

  /// Whether the queue is currently processing tasks.
  bool get isProcessing => _isProcessing;

  /// Current number of tasks in the queue.
  int get queueLength => _queue.length;

  /// Adds a task to the queue.
  ///
  /// If a task for the same page already exists, updates its priority
  /// if the new priority is higher.
  void enqueue(ThumbnailTask task) {
    if (_isDisposed) return;

    // Check if page is already in queue
    final existingIndex = _queue.indexWhere(
      (t) => t.page.id == task.page.id,
    );

    if (existingIndex != -1) {
      // Update priority if higher
      final existing = _queue[existingIndex];
      if (task.priority > existing.priority) {
        _queue[existingIndex] = task;
        _sortQueue();
      }
      return;
    }

    // Add new task
    _queue.add(task);
    _sortQueue();

    // Start processing if needed
    if (_isProcessing) {
      _processNext();
    }
  }

  /// Removes a page from the queue by page ID.
  void removePageFromQueue(String pageId) {
    _queue.removeWhere((task) => task.page.id == pageId);
  }

  /// Clears all pending tasks from the queue.
  void clear() {
    _queue.clear();
  }

  /// Starts processing the queue.
  void startProcessing() {
    if (_isDisposed) return;
    _isProcessing = true;
    _processNext();
  }

  /// Stops processing the queue.
  void stopProcessing() {
    _isProcessing = false;
  }

  /// Sorts the queue by priority (highest first).
  void _sortQueue() {
    _queue.sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Processes the next task in the queue.
  void _processNext() {
    if (_isDisposed || !_isProcessing) return;

    // Check if we can process more tasks
    if (_activeTasks.length >= maxConcurrent) return;

    // Get next task
    if (_queue.isEmpty) return;

    // Find first task that's not already being processed
    ThumbnailTask? task;
    for (int i = 0; i < _queue.length; i++) {
      if (!_processingPageIds.contains(_queue[i].page.id)) {
        task = _queue.removeAt(i);
        break;
      }
    }

    if (task == null) return;

    // Process the task
    final future = _processTask(task);
    _activeTasks.add(future);

    future.then((_) {
      _activeTasks.remove(future);
      _processNext(); // Process next task
    });

    // Continue processing if slots available
    if (_activeTasks.length < maxConcurrent) {
      _processNext();
    }
  }

  /// Processes a single task.
  Future<void> _processTask(ThumbnailTask task) async {
    if (_isDisposed) return;

    final pageId = task.page.id;
    _processingPageIds.add(pageId);

    try {
      // Check if already in cache
      final cacheKey = ThumbnailGenerator.getCacheKey(task.page);
      if (cache.contains(cacheKey)) {
        final cachedData = cache.get(cacheKey);
        onTaskComplete?.call(task, cachedData);
        return;
      }

      // Generate thumbnail
      final data = await ThumbnailGenerator.generate(
        task.page,
        width: task.width,
        height: task.height,
        backgroundColor: task.backgroundColor,
      );

      if (_isDisposed) return;

      if (data != null) {
        // Cache the result
        cache.put(cacheKey, data);
        onTaskComplete?.call(task, data);
      } else {
        onTaskError?.call(task, Exception('Failed to generate thumbnail'));
      }
    } catch (error) {
      if (!_isDisposed) {
        onTaskError?.call(task, error);
      }
    } finally {
      _processingPageIds.remove(pageId);
    }
  }

  /// Disposes the queue and stops all processing.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isProcessing = false;
    _queue.clear();
    _processingPageIds.clear();
    _activeTasks.clear();
  }
}
