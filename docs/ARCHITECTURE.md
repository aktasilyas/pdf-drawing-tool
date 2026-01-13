# Architecture Documentation

## Overview

This project follows a **library-first, multi-package architecture** designed to produce both a reusable pub.dev library and a full-featured StarNote-like application from the same codebase.

## Package Structure

```
starnote_drawing_workspace/
├── packages/
│   ├── drawing_core/      # Pure logic, data structures, tool abstractions
│   ├── drawing_ui/        # Flutter widgets, painters, panels
│   └── drawing_toolkit/   # Umbrella package for public API
├── example_app/           # StarNote-like consumer application
└── docs/                  # Documentation
```

## Dependency Direction (STRICTLY ENFORCED)

```
┌─────────────────────────────────────────────────────────────┐
│                       example_app                            │
│            (Application layer - consumes library)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     drawing_toolkit                          │
│          (Umbrella package - stable public API)              │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────┐
│      drawing_ui         │     │                             │
│   (Flutter widgets)     │────▶│       drawing_core          │
│                         │     │     (Pure logic/models)     │
└─────────────────────────┘     └─────────────────────────────┘
```

### Rules

1. **`drawing_core`** has NO dependency on `drawing_ui` or `example_app`
2. **`drawing_ui`** depends ONLY on `drawing_core`
3. **`drawing_toolkit`** depends on both `drawing_core` and `drawing_ui`
4. **`example_app`** depends ONLY on `drawing_toolkit` (not directly on core/ui)
5. **No circular dependencies** - this is enforced by Dart's package system

## Package Responsibilities

### `drawing_core`

**Purpose**: Platform-agnostic business logic and data structures.

**Contains**:
- Data models (`Stroke`, `Point`, `Layer`, `Document`)
- Tool abstractions (`DrawingTool`, `ToolSettings`)
- History management (`Command`, `HistoryStack`)
- Serialization interfaces and implementations
- Utility functions (path smoothing, geometry)
- Repository interfaces (abstract only)
- Selection context models
- Metadata extraction utilities

**Does NOT contain**:
- Flutter widgets
- UI-specific logic
- Platform-specific code (ideally)
- ⛔ Premium/subscription logic
- ⛔ AI integration
- ⛔ Database implementations
- ⛔ Network calls

**Ideal dependency**: Pure Dart (no Flutter dependency if possible, or minimal `dart:ui` for `Offset`, `Color`, etc.)

### `drawing_ui`

**Purpose**: Flutter widgets and rendering components.

**Contains**:
- `DrawingCanvas` widget
- `CustomPainter` implementations
- Toolbar widgets
- Panel widgets (tool settings overlays)
- Pen box (preset sidebar)
- Theme definitions
- Reusable UI components

**Does NOT contain**:
- ⛔ Premium/subscription logic
- ⛔ AI integration
- ⛔ Database implementations
- ⛔ Network calls
- ⛔ Feature gating logic

**Depends on**: `drawing_core`

### `drawing_toolkit`

**Purpose**: Umbrella package providing a stable, curated public API.

**Contains**:
- Re-exports of stable public APIs from `drawing_core` and `drawing_ui`
- Integration helpers
- Convenience constructors
- Default configurations

**Depends on**: `drawing_core`, `drawing_ui`

### `example_app`

**Purpose**: Full-featured application demonstrating library usage.

**Contains**:
- App-specific features (settings, persistence, navigation)
- Riverpod providers
- Platform integrations (image picker, camera)
- Asset management (stickers, icons)
- ✅ Premium/Free feature gating
- ✅ AI assistant integration
- ✅ Database implementations (Isar/Hive)
- ✅ Subscription management
- ✅ Analytics

**Depends on**: `drawing_toolkit` only

---

## Public API Rules

### Export Strategy

Each package has a single entry point that exports only public API:

```dart
// packages/drawing_core/lib/drawing_core.dart
library drawing_core;

export 'src/models/stroke.dart' show Stroke, StrokeStyle;
export 'src/models/point.dart' show DrawingPoint;
// ... explicit exports only
```

### Visibility Rules

| Location | Visibility |
|----------|------------|
| `lib/<package>.dart` | Public entry point |
| `lib/src/**` | Private implementation |
| `lib/src/**/internal.dart` | Strictly internal |

### Naming Conventions

- **Public classes**: Descriptive, prefixed if needed (`DrawingCanvas`, `DrawingTool`)
- **Private classes**: Prefixed with underscore in implementation
- **Interfaces**: Suffix with intent (`Serializable`, `Configurable`) or use abstract class
- **Providers**: Suffix with `Provider` (`currentToolProvider`)

### Documentation Requirements

All public API must include:

```dart
/// Brief description of the class/function.
///
/// Longer description if needed, explaining:
/// - When to use this
/// - How it relates to other components
/// - Any important constraints
///
/// Example:
/// ```dart
/// final stroke = Stroke(
///   points: [...],
///   style: StrokeStyle.ballpoint(),
/// );
/// ```
///
/// See also:
/// - [RelatedClass] for related functionality
class PublicClass { ... }
```

---

## State Management Architecture

### Riverpod Provider Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Widgets)                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Provider Layer                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ currentTool     │  │ toolSettings    │  │ document     │ │
│  │ Provider        │  │ Provider        │  │ Provider     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ penBoxPresets   │  │ toolbarConfig   │  │ history      │ │
│  │ Provider        │  │ Provider        │  │ Provider     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ featureGate     │  │ aiAssistant     │  │ subscription │ │
│  │ Provider (APP)  │  │ Provider (APP)  │  │ Provider(APP)│ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Service Layer                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │ Persistence     │  │ ImagePicker     │  │ Export       │ │
│  │ Service (APP)   │  │ Service         │  │ Service      │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │ AI Assistant    │  │ Subscription    │                   │
│  │ Service (APP)   │  │ Service (APP)   │                   │
│  └─────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### Provider Definitions (App Layer)

```dart
// Tool selection
final currentToolProvider = StateProvider<ToolType>((ref) => ToolType.pen);

// Tool-specific settings (family provider)
final toolSettingsProvider = StateNotifierProvider.family<ToolSettingsNotifier, ToolSettings, ToolType>(...);

// Document state
final documentProvider = StateNotifierProvider<DocumentNotifier, DrawingDocument>(...);

// History
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>(...);

// Persistence (interface in library, implementation in app)
final persistenceServiceProvider = Provider<PersistenceService>(...);

// APP LAYER ONLY - Feature gating
final featureGateProvider = Provider<FeatureGate>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return ProductionFeatureGate(subscription);
});

// APP LAYER ONLY - AI assistant
final aiAssistantProvider = Provider<AIAssistantService>((ref) {
  return OpenAIAssistantService(apiKey: ref.watch(configProvider).openAiKey);
});
```

### Separation of Concerns

- **Library packages**: Define interfaces for persistence, export, etc.
- **App layer**: Provides concrete implementations
- **Dependency injection**: Via Riverpod providers

---

## ⭐ Monetization & Premium Strategy (App Layer Only)

> **CRITICAL**: All monetization logic MUST reside in the `example_app` layer.  
> The library packages (`drawing_core`, `drawing_ui`, `drawing_toolkit`) MUST remain completely unaware of premium/free concepts.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    example_app (App Layer)                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │               Monetization Layer                         ││
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  ││
│  │  │FeatureGate  │  │Subscription  │  │ StoreKit /     │  ││
│  │  │(interface)  │  │Service       │  │ RevenueCat     │  ││
│  │  └──────┬──────┘  └──────┬───────┘  └───────┬────────┘  ││
│  │         │                │                   │           ││
│  │         ▼                ▼                   ▼           ││
│  │  ┌─────────────────────────────────────────────────────┐││
│  │  │         Premium UI Gating (Widgets)                 │││
│  │  │  - LockedOverlay                                    │││
│  │  │  - PremiumBadge                                     │││
│  │  │  - Upgrade prompts                                  │││
│  │  └─────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              │ uses (NO premium awareness)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              drawing_toolkit / drawing_ui / drawing_core     │
│                                                              │
│    ToolCapability.basic       ←── App maps to Free tier      │
│    ToolCapability.advanced    ←── App maps to Pro tier       │
│    ToolCapability.experimental ←── App maps to Beta/Pro      │
│                                                              │
│    (Library has NO knowledge of "premium", "free", etc.)     │
└─────────────────────────────────────────────────────────────┘
```

### Key Interfaces (App Layer)

```dart
// ===== All of these are in example_app ONLY =====

/// Feature identifiers for gating.
enum FeatureId {
  // Drawing tools
  advancedBrushes,
  texturePencil,
  customNibs,
  
  // Content
  customStickers,
  unlimitedLayers,
  
  // AI features
  aiAssistant,
  aiSuggestions,
  handwritingRecognition,
  
  // Export
  pdfExport,
  svgExport,
  highResExport,
  
  // Sync
  cloudSync,
  deviceSync,
}

/// Abstract interface for checking feature availability.
abstract class FeatureGate {
  /// Check if a feature is currently enabled for the user.
  bool isFeatureEnabled(FeatureId feature);
  
  /// Stream of enabled features (updates on subscription changes).
  Stream<Set<FeatureId>> get enabledFeaturesStream;
  
  /// Get the required tier for a feature.
  SubscriptionTier? requiredTierFor(FeatureId feature);
}

/// Subscription tiers.
enum SubscriptionTier {
  free,
  pro,
  proPlus,
  team,
}
```

### Mapping Library Capabilities to App Features

The library defines generic `ToolCapability` values. The app layer maps these to premium tiers:

```dart
// In example_app - NOT in library
class CapabilityToFeatureMapper {
  static Set<FeatureId> mapCapabilities(Set<ToolCapability> capabilities) {
    final features = <FeatureId>{};
    
    for (final cap in capabilities) {
      switch (cap) {
        case ToolCapability.basic:
          // No feature gating needed
          break;
        case ToolCapability.advanced:
          features.add(FeatureId.advancedBrushes);
          break;
        case ToolCapability.experimental:
          features.add(FeatureId.advancedBrushes);
          break;
        case ToolCapability.cpuIntensive:
          // Performance warning, not feature gating
          break;
        case ToolCapability.requiresNetwork:
          // Network check, not premium
          break;
      }
    }
    
    return features;
  }
}
```

### Premium UI Patterns

```dart
// Wrapping a tool button with premium gating
class GatedToolButton extends ConsumerWidget {
  final ToolType tool;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureGate = ref.watch(featureGateProvider);
    final toolCapabilities = ref.watch(toolCapabilitiesProvider(tool));
    final requiredFeatures = CapabilityToFeatureMapper.mapCapabilities(toolCapabilities);
    
    final isLocked = requiredFeatures.any((f) => !featureGate.isFeatureEnabled(f));
    
    return ToolButton(
      tool: tool,
      isLocked: isLocked,
      onTap: isLocked ? null : () => _selectTool(tool),
      onLockedTap: () => _showUpgradePrompt(context, requiredFeatures),
    );
  }
}
```

### What the Library MUST NOT Contain

❌ No `isPremium`, `isFree`, `isLocked` properties in core/ui  
❌ No `SubscriptionTier`, `FeatureId` enums in core/ui  
❌ No `checkPremium()` or `requireSubscription()` methods  
❌ No RevenueCat, StoreKit, or payment SDK imports  
❌ No "upgrade" or "subscribe" strings in library code  

### Verification Tests

```dart
// test/architecture/premium_isolation_test.dart
test('drawing_core has no premium concepts', () {
  final coreFiles = Directory('packages/drawing_core/lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  
  for (final file in coreFiles) {
    final content = file.readAsStringSync().toLowerCase();
    expect(content, isNot(contains('premium')));
    expect(content, isNot(contains('subscription')));
    expect(content, isNot(contains('upgrade')));
    expect(content, isNot(contains('free tier')));
    expect(content, isNot(contains('pro tier')));
  }
});
```

---

## ⭐ AI Integration Strategy (App Layer Only)

> **CRITICAL**: All AI logic MUST reside in the `example_app` layer.  
> The library provides data extraction utilities but has NO knowledge of AI, LLMs, or inference.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    example_app (App Layer)                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    AI Integration Layer                  ││
│  │  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐  ││
│  │  │AIAssistant    │  │OpenAI /      │  │Response      │  ││
│  │  │Service        │  │Anthropic SDK │  │Cache         │  ││
│  │  └───────┬───────┘  └──────┬───────┘  └──────┬───────┘  ││
│  │          │                 │                  │          ││
│  │          ▼                 ▼                  ▼          ││
│  │  ┌─────────────────────────────────────────────────────┐││
│  │  │              AI UI Components                       │││
│  │  │  - AIAssistantPanel                                 │││
│  │  │  - AskAIButton                                      │││
│  │  │  - SuggestionChips                                  │││
│  │  └─────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              │ uses (NO AI awareness)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              drawing_core (Library)                          │
│                                                              │
│    SelectionContext     ←── Pure data model                  │
│    DrawingMetadata      ←── Structured extraction            │
│    TextExtractor        ←── Content extraction utility       │
│    RegionRasterizer     ←── Image generation utility         │
│                                                              │
│    (Library has NO knowledge of AI, LLM, inference, etc.)    │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow: Selection → AI → Response

```
┌──────────┐    ┌───────────────┐    ┌──────────────┐    ┌─────────────┐
│  User    │───▶│  Selection    │───▶│  Context     │───▶│  AI Service │
│  Selects │    │  System       │    │  Builder     │    │  (App)      │
│          │    │  (Library)    │    │  (App)       │    │             │
└──────────┘    └───────────────┘    └──────────────┘    └──────┬──────┘
                                                                 │
                                                                 ▼
┌──────────┐    ┌───────────────┐    ┌──────────────┐    ┌─────────────┐
│  Display │◀───│  Response     │◀───│  AI Panel    │◀───│  LLM API    │
│  Result  │    │  Formatter    │    │  (App UI)    │    │  Response   │
│          │    │  (App)        │    │              │    │             │
└──────────┘    └───────────────┘    └──────────────┘    └─────────────┘
```

### Library-Provided Data Models (No AI Logic)

```dart
// In drawing_core - pure data, NO AI knowledge

/// Represents the user's current selection.
/// This is a data transfer object with no behavior.
class SelectionContext {
  final String id;
  final List<Stroke> selectedStrokes;
  final List<TextBox> selectedTextBoxes;
  final List<ImageElement> selectedImages;
  final Rect? selectionBounds;
  final DateTime timestamp;
  
  /// Convert to JSON for external consumption.
  Map<String, dynamic> toJson() => { ... };
  
  /// Estimated content hash for caching.
  String get contentHash => ...;
}

/// Metadata about drawing content.
/// Useful for analytics, export, or external processing.
class DrawingMetadata {
  final int strokeCount;
  final int layerCount;
  final Map<String, int> toolUsageStats;
  final Rect contentBounds;
  final Duration estimatedDrawingTime;
  
  Map<String, dynamic> toJson() => { ... };
}
```

### Library-Provided Extraction Utilities (No AI Logic)

```dart
// In drawing_core - extraction utilities, NO AI knowledge

/// Extracts text content from drawing elements.
class TextExtractor {
  /// Extract all text boxes from a selection.
  List<ExtractedText> extractFromSelection(SelectionContext selection) {
    // Returns raw text data - interpretation is caller's responsibility
  }
}

/// Converts selection to raster image.
class RegionRasterizer {
  /// Rasterize selection bounds to PNG bytes.
  /// The caller decides what to do with the image (export, AI vision, etc.)
  Future<Uint8List> rasterizeSelection(
    SelectionContext selection, {
    int maxDimension = 1024,
  });
}
```

### App Layer AI Service (App Only)

```dart
// In example_app ONLY - NOT in library packages

/// AI assistant service interface.
abstract class AIAssistantService {
  /// Ask a question about the selected content.
  Future<AIResponse> askAboutSelection(
    SelectionContext selection,
    String userQuestion,
  );
  
  /// Summarize entire document.
  Future<AIResponse> summarizeDocument(DrawingDocument doc);
  
  /// Get smart suggestions.
  Future<List<AISuggestion>> getSuggestions(SelectionContext selection);
  
  /// Stream response for real-time display.
  Stream<String> streamResponse(String prompt);
}

/// Concrete implementation using OpenAI.
class OpenAIAssistantService implements AIAssistantService {
  final String apiKey;
  final http.Client _client;
  
  @override
  Future<AIResponse> askAboutSelection(
    SelectionContext selection,
    String userQuestion,
  ) async {
    // 1. Extract text using library utility
    final textExtractor = TextExtractor();
    final texts = textExtractor.extractFromSelection(selection);
    
    // 2. Rasterize region if needed
    final rasterizer = RegionRasterizer();
    final imageBytes = await rasterizer.rasterizeSelection(selection);
    
    // 3. Build prompt (app-layer concern)
    final prompt = _buildPrompt(texts, imageBytes, userQuestion);
    
    // 4. Call AI API (app-layer concern)
    final response = await _callOpenAI(prompt);
    
    return AIResponse(content: response);
  }
}
```

### AI Context Builder (App Only)

```dart
// In example_app ONLY

/// Builds context for AI requests.
class AIContextBuilder {
  /// Build comprehensive context from selection.
  Future<AIContext> buildContext(SelectionContext selection) async {
    // Extract all available data using library utilities
    final textExtractor = TextExtractor();
    final texts = textExtractor.extractFromSelection(selection);
    
    final strokeExtractor = StrokeExtractor();
    final strokeData = strokeExtractor.extractFromSelection(selection);
    
    final rasterizer = RegionRasterizer();
    final image = await rasterizer.rasterizeSelection(selection);
    
    // Build AI-ready context (app-layer formatting)
    return AIContext(
      extractedTexts: texts,
      strokeSummary: _summarizeStrokes(strokeData),
      imageBase64: base64Encode(image),
      selectionBounds: selection.selectionBounds,
    );
  }
}
```

### What the Library MUST NOT Contain

❌ No `AIService`, `LLMClient`, `ChatCompletion` classes  
❌ No `prompt`, `completion`, `inference` terminology  
❌ No OpenAI, Anthropic, or other AI SDK imports  
❌ No `askAI()`, `generateResponse()`, `chat()` methods  
❌ No API key handling or AI configuration  

### Verification Tests

```dart
// test/architecture/ai_isolation_test.dart
test('drawing_core has no AI concepts', () {
  final coreFiles = Directory('packages/drawing_core/lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  
  for (final file in coreFiles) {
    final content = file.readAsStringSync();
    expect(content.toLowerCase(), isNot(contains('openai')));
    expect(content.toLowerCase(), isNot(contains('anthropic')));
    expect(content.toLowerCase(), isNot(contains('llm')));
    expect(content.toLowerCase(), isNot(contains('chatgpt')));
    expect(content, isNot(contains('AIService')));
    expect(content, isNot(contains('askAI')));
  }
});
```

---

## Local-First Database Strategy

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    example_app (App Layer)                   │
│  ┌─────────────────────────────────────────────────────────┐│
│  │               Persistence Implementation                 ││
│  │  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐  ││
│  │  │Isar Database  │  │Migration     │  │Thumbnail     │  ││
│  │  │               │  │Manager       │  │Cache         │  ││
│  │  └───────┬───────┘  └──────────────┘  └──────────────┘  ││
│  │          │                                               ││
│  │          ▼                                               ││
│  │  ┌─────────────────────────────────────────────────────┐││
│  │  │         Repository Implementations                  │││
│  │  │  - IsarDocumentRepository                           │││
│  │  │  - IsarSettingsRepository                           │││
│  │  │  - IsarPresetRepository                             │││
│  │  └─────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              │ implements
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              drawing_core (Library)                          │
│                                                              │
│    DocumentRepository (abstract interface)                   │
│    SettingsRepository (abstract interface)                   │
│    PresetRepository (abstract interface)                     │
│                                                              │
│    (Interfaces ONLY - no implementation, no database deps)   │
└─────────────────────────────────────────────────────────────┘
```

### Repository Interfaces (Library)

```dart
// In drawing_core - interfaces only

/// Abstract interface for document persistence.
abstract class DocumentRepository {
  Future<String> save(DrawingDocument document);
  Future<DrawingDocument?> load(String documentId);
  Future<void> delete(String documentId);
  Future<List<DocumentSummary>> listAll();
  Stream<DrawingDocument> watchDocument(String documentId);
}

/// Lightweight document info for listings.
class DocumentSummary {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Uint8List? thumbnail;
  final int strokeCount;
}
```

### Database Implementation (App Only)

```dart
// In example_app ONLY

@collection
class DocumentEntity {
  Id id = Isar.autoIncrement;
  
  late String documentId;
  late String title;
  late DateTime createdAt;
  late DateTime updatedAt;
  late List<byte> serializedData;
  late List<byte>? thumbnail;
  
  @Index()
  String get titleIndex => title.toLowerCase();
}

class IsarDocumentRepository implements DocumentRepository {
  final Isar _isar;
  
  @override
  Future<String> save(DrawingDocument document) async {
    final entity = DocumentEntity()
      ..documentId = document.id
      ..title = document.title
      ..serializedData = DocumentSerializer.serialize(document)
      ..updatedAt = DateTime.now();
    
    await _isar.writeTxn(() => _isar.documentEntitys.put(entity));
    return document.id;
  }
  
  // ... other implementations
}
```

---

## File Organization

### Within Each Package

```
lib/
├── <package_name>.dart    # Public API exports only
└── src/
    ├── models/            # Data classes
    ├── tools/             # Tool implementations (core)
    ├── widgets/           # Flutter widgets (ui)
    ├── painters/          # CustomPainter classes (ui)
    ├── history/           # Undo/redo system (core)
    ├── serialization/     # JSON/binary codecs (core)
    ├── selection/         # Selection models & utilities (core)
    └── utils/             # Helper functions
```

### Test Organization

```
test/
├── unit/                  # Pure logic tests
├── widget/                # Widget tests
├── golden/                # Golden image tests
├── integration/           # Integration tests
├── architecture/          # Architecture compliance tests
└── fixtures/              # Test data
```

---

## Extension Points

The library is designed for extensibility:

### Custom Tools

```dart
class MyCustomTool extends DrawingTool {
  @override
  Set<ToolCapability> get capabilities => {ToolCapability.basic};
  
  @override
  void onPointerDown(DrawingPoint point) { ... }
  
  @override
  void onPointerMove(DrawingPoint point) { ... }
  
  @override
  void onPointerUp() { ... }
}

// Register with toolkit
drawingController.registerTool('myTool', MyCustomTool());
```

### Custom Persistence

```dart
// App layer implementation
class CloudPersistence implements DocumentRepository {
  @override
  Future<String> save(DrawingDocument doc) async { ... }
  
  @override
  Future<DrawingDocument?> load(String id) async { ... }
}
```

### Custom Rendering

```dart
class MyStrokePainter extends StrokePainter {
  @override
  void paintStroke(Canvas canvas, Stroke stroke) {
    // Custom rendering logic
  }
}
```

---

## Performance Considerations

See `docs/PERFORMANCE_STRATEGY.md` for detailed performance architecture.

Key architectural decisions for performance:

1. **Immutable data models** with efficient copying
2. **Command pattern** for undo/redo (not full state copies)
3. **Layered rendering** to minimize repaints
4. **Caching strategy** with invalidation triggers
5. **Separate UI and canvas repaints**
6. **Isolate-based AI context preparation** (app layer)

---

## Testing Strategy

| Package | Test Types |
|---------|------------|
| `drawing_core` | Unit tests (100% coverage goal) |
| `drawing_ui` | Widget tests, Golden tests |
| `drawing_toolkit` | Integration tests |
| `example_app` | Integration tests, E2E |

### Architecture Compliance Tests

```dart
// Verify layer separation
test('core has no UI imports', () { ... });
test('core has no premium concepts', () { ... });
test('core has no AI concepts', () { ... });
test('core has no database implementations', () { ... });
test('ui has no premium concepts', () { ... });
test('ui has no AI concepts', () { ... });
```

### Golden Test Strategy

- Capture key UI states (tool selected, panel open, etc.)
- Capture stroke rendering appearance
- Capture locked/unlocked states
- Capture AI panel states
- Platform-specific golden files if needed

---

## Versioning Strategy

- Follow [Semantic Versioning](https://semver.org/)
- All packages versioned together (melos handles this)
- Pre-1.0: API may change between minors
- Post-1.0: Strict semver adherence

---

## Security Considerations

- No sensitive data handling in library
- Image assets sanitized before processing
- Export formats validated
- No network calls in library packages (app layer only)
- API keys managed in app layer only
- User data encryption in app layer persistence
