# Phase 4E-5: Toolbar UX Improvements - Cursor Talimatları

> **Modül:** Toolbar UX Improvements  
> **Öncelik:** 🟡 Orta  
> **Tahmini Süre:** 3-4 saat  
> **Branch:** feature/phase4e-enhancements

---

## ⚠️ KRİTİK KURALLAR (HER ADIMDA UYGULA)

```
1. TEST FIRST: Her adımda test dosyası oluştur
2. CURRENT_STATUS.md: Her adım sonrası güncelle
3. CHECKLIST_TODO.md: Tamamlanan maddeleri işaretle
4. TABLET TESTİ: Commit öncesi MUTLAKA tablet/emülatörde test et
5. MEVCUT YAPIYI BOZMA: Toolbar çalışmaya devam etmeli
```

---

## 📋 Modül Özeti

**Amaç:** Toolbar'ı daha kullanıcı dostu ve özelleştirilebilir hale getir

**Mevcut Durum:**
- ✅ Toolbar temel yapısı var
- ✅ Tool butonları çalışıyor
- ❌ Settings panel eksik/yetersiz
- ❌ Tool sıralama yok
- ❌ Tool gizleme yok
- ❌ Ayarlar kalıcı değil

**Hedef:**
- Settings panel tam çalışır
- Araçlar sürükle-bırak ile sıralanabilir
- Araçlar gösterilebilir/gizlenebilir
- Ayarlar cihazda saklanır
- %85+ test coverage

---

## 📁 Dosya Yapısı

```
packages/drawing_ui/lib/src/
├── panels/
│   └── toolbar_settings_panel.dart (YENİ/GÜNCELLE)
├── providers/
│   ├── toolbar_config_provider.dart (GÜNCELLE)
│   └── toolbar_persistence_provider.dart (YENİ)
├── widgets/
│   ├── reorderable_tool_list.dart (YENİ)
│   ├── tool_visibility_toggle.dart (YENİ)
│   └── toolbar.dart (GÜNCELLE)
└── models/
    └── toolbar_config.dart (YENİ/GÜNCELLE)

test/
├── panels/toolbar_settings_panel_test.dart (YENİ)
├── providers/toolbar_config_provider_test.dart (YENİ)
└── widgets/reorderable_tool_list_test.dart (YENİ)
```

---

## ADIM 1: Toolbar Config Model (drawing_ui)

### Görev
Toolbar konfigürasyonunu yönetecek model oluştur

### Dosya: `packages/drawing_ui/lib/src/models/toolbar_config.dart`

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

/// Configuration for a single tool in the toolbar.
@immutable
class ToolConfig {
  const ToolConfig({
    required this.toolType,
    this.isVisible = true,
    this.order = 0,
  });

  final ToolType toolType;
  final bool isVisible;
  final int order;

  ToolConfig copyWith({
    ToolType? toolType,
    bool? isVisible,
    int? order,
  }) {
    return ToolConfig(
      toolType: toolType ?? this.toolType,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'toolType': toolType.name,
    'isVisible': isVisible,
    'order': order,
  };

  factory ToolConfig.fromJson(Map<String, dynamic> json) {
    return ToolConfig(
      toolType: ToolType.values.firstWhere(
        (t) => t.name == json['toolType'],
        orElse: () => ToolType.pen,
      ),
      isVisible: json['isVisible'] ?? true,
      order: json['order'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolConfig &&
          runtimeType == other.runtimeType &&
          toolType == other.toolType &&
          isVisible == other.isVisible &&
          order == other.order;

  @override
  int get hashCode => Object.hash(toolType, isVisible, order);
}

/// Complete toolbar configuration.
@immutable
class ToolbarConfig {
  const ToolbarConfig({
    required this.tools,
    this.showQuickAccess = true,
    this.quickAccessColors = const [],
    this.quickAccessThicknesses = const [],
  });

  final List<ToolConfig> tools;
  final bool showQuickAccess;
  final List<int> quickAccessColors; // Color values
  final List<double> quickAccessThicknesses;

  /// Default toolbar configuration
  factory ToolbarConfig.defaultConfig() {
    final defaultTools = [
      ToolType.pen,
      ToolType.pencil,
      ToolType.highlighter,
      ToolType.eraser,
      ToolType.lasso,
      ToolType.shapes,
      ToolType.text,
      ToolType.image,
    ];

    return ToolbarConfig(
      tools: defaultTools.asMap().entries.map((e) => ToolConfig(
        toolType: e.value,
        isVisible: true,
        order: e.key,
      )).toList(),
      showQuickAccess: true,
      quickAccessColors: const [
        0xFF000000, // Black
        0xFF2196F3, // Blue
        0xFFF44336, // Red
        0xFF4CAF50, // Green
        0xFFFF9800, // Orange
      ],
      quickAccessThicknesses: const [1.0, 2.0, 4.0],
    );
  }

  /// Get visible tools sorted by order
  List<ToolConfig> get visibleTools {
    return tools
        .where((t) => t.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Get all tools sorted by order
  List<ToolConfig> get sortedTools {
    return List<ToolConfig>.from(tools)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  ToolbarConfig copyWith({
    List<ToolConfig>? tools,
    bool? showQuickAccess,
    List<int>? quickAccessColors,
    List<double>? quickAccessThicknesses,
  }) {
    return ToolbarConfig(
      tools: tools ?? this.tools,
      showQuickAccess: showQuickAccess ?? this.showQuickAccess,
      quickAccessColors: quickAccessColors ?? this.quickAccessColors,
      quickAccessThicknesses: quickAccessThicknesses ?? this.quickAccessThicknesses,
    );
  }

  /// Update a specific tool's config
  ToolbarConfig updateTool(ToolType toolType, ToolConfig Function(ToolConfig) update) {
    final newTools = tools.map((t) {
      if (t.toolType == toolType) {
        return update(t);
      }
      return t;
    }).toList();
    return copyWith(tools: newTools);
  }

  /// Toggle tool visibility
  ToolbarConfig toggleToolVisibility(ToolType toolType) {
    return updateTool(toolType, (t) => t.copyWith(isVisible: !t.isVisible));
  }

  /// Reorder tools
  ToolbarConfig reorderTools(int oldIndex, int newIndex) {
    final sorted = sortedTools;
    final tool = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, tool);
    
    // Update order values
    final newTools = sorted.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();
    
    return copyWith(tools: newTools);
  }

  /// Reset to default
  ToolbarConfig reset() => ToolbarConfig.defaultConfig();

  Map<String, dynamic> toJson() => {
    'tools': tools.map((t) => t.toJson()).toList(),
    'showQuickAccess': showQuickAccess,
    'quickAccessColors': quickAccessColors,
    'quickAccessThicknesses': quickAccessThicknesses,
  };

  factory ToolbarConfig.fromJson(Map<String, dynamic> json) {
    return ToolbarConfig(
      tools: (json['tools'] as List<dynamic>?)
          ?.map((t) => ToolConfig.fromJson(t as Map<String, dynamic>))
          .toList() ?? ToolbarConfig.defaultConfig().tools,
      showQuickAccess: json['showQuickAccess'] ?? true,
      quickAccessColors: (json['quickAccessColors'] as List<dynamic>?)
          ?.map((c) => c as int)
          .toList() ?? const [],
      quickAccessThicknesses: (json['quickAccessThicknesses'] as List<dynamic>?)
          ?.map((t) => (t as num).toDouble())
          .toList() ?? const [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ToolbarConfig.fromJsonString(String jsonString) {
    return ToolbarConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
```

### Test Dosyası: `test/models/toolbar_config_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/providers/providers.dart';

void main() {
  group('ToolConfig', () {
    test('creates with default values', () {
      const config = ToolConfig(toolType: ToolType.pen);
      
      expect(config.isVisible, isTrue);
      expect(config.order, equals(0));
    });

    test('copyWith works correctly', () {
      const config = ToolConfig(toolType: ToolType.pen, isVisible: true);
      final updated = config.copyWith(isVisible: false);
      
      expect(updated.isVisible, isFalse);
      expect(updated.toolType, equals(ToolType.pen));
    });

    test('JSON serialization roundtrip', () {
      const config = ToolConfig(
        toolType: ToolType.eraser,
        isVisible: false,
        order: 5,
      );
      
      final json = config.toJson();
      final restored = ToolConfig.fromJson(json);
      
      expect(restored, equals(config));
    });
  });

  group('ToolbarConfig', () {
    test('defaultConfig has all tools visible', () {
      final config = ToolbarConfig.defaultConfig();
      
      expect(config.tools.every((t) => t.isVisible), isTrue);
      expect(config.tools.length, greaterThan(5));
    });

    test('visibleTools filters hidden tools', () {
      var config = ToolbarConfig.defaultConfig();
      config = config.toggleToolVisibility(ToolType.eraser);
      
      final visible = config.visibleTools;
      
      expect(visible.any((t) => t.toolType == ToolType.eraser), isFalse);
    });

    test('reorderTools updates order correctly', () {
      final config = ToolbarConfig.defaultConfig();
      final firstTool = config.sortedTools.first.toolType;
      
      final reordered = config.reorderTools(0, 3);
      final sorted = reordered.sortedTools;
      
      expect(sorted[3].toolType, equals(firstTool));
    });

    test('JSON serialization roundtrip', () {
      final config = ToolbarConfig.defaultConfig();
      
      final jsonString = config.toJsonString();
      final restored = ToolbarConfig.fromJsonString(jsonString);
      
      expect(restored.tools.length, equals(config.tools.length));
      expect(restored.showQuickAccess, equals(config.showQuickAccess));
    });

    test('reset returns default config', () {
      var config = ToolbarConfig.defaultConfig();
      config = config.toggleToolVisibility(ToolType.pen);
      config = config.toggleToolVisibility(ToolType.eraser);
      
      final reset = config.reset();
      
      expect(reset.tools.every((t) => t.isVisible), isTrue);
    });
  });
}
```

### Checklist
```
□ toolbar_config.dart oluşturuldu
□ ToolConfig model eklendi
□ ToolbarConfig model eklendi
□ JSON serialization eklendi
□ toolbar_config_test.dart oluşturuldu
□ Barrel export güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-5: [█_____] 1/5)
□ TABLET TESTİ yapıldı
□ Commit: feat(ui): add ToolbarConfig model with serialization
```

---

## ADIM 2: Toolbar Config Provider (drawing_ui)

### Görev
Toolbar konfigürasyonunu yönetecek provider oluştur

### Dosya: `packages/drawing_ui/lib/src/providers/toolbar_config_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// Key for storing toolbar config in SharedPreferences
const _toolbarConfigKey = 'starnote_toolbar_config';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

/// Provider for toolbar configuration with persistence
final toolbarConfigProvider = StateNotifierProvider<ToolbarConfigNotifier, ToolbarConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ToolbarConfigNotifier(prefs);
});

/// Notifier for managing toolbar configuration
class ToolbarConfigNotifier extends StateNotifier<ToolbarConfig> {
  ToolbarConfigNotifier(this._prefs) : super(_loadConfig(_prefs));

  final SharedPreferences _prefs;

  static ToolbarConfig _loadConfig(SharedPreferences prefs) {
    final jsonString = prefs.getString(_toolbarConfigKey);
    if (jsonString != null) {
      try {
        return ToolbarConfig.fromJsonString(jsonString);
      } catch (e) {
        // Invalid JSON, return default
        return ToolbarConfig.defaultConfig();
      }
    }
    return ToolbarConfig.defaultConfig();
  }

  Future<void> _saveConfig() async {
    await _prefs.setString(_toolbarConfigKey, state.toJsonString());
  }

  /// Toggle visibility of a tool
  Future<void> toggleToolVisibility(ToolType toolType) async {
    state = state.toggleToolVisibility(toolType);
    await _saveConfig();
  }

  /// Reorder tools
  Future<void> reorderTools(int oldIndex, int newIndex) async {
    state = state.reorderTools(oldIndex, newIndex);
    await _saveConfig();
  }

  /// Toggle quick access bar visibility
  Future<void> toggleQuickAccess() async {
    state = state.copyWith(showQuickAccess: !state.showQuickAccess);
    await _saveConfig();
  }

  /// Update quick access colors
  Future<void> setQuickAccessColors(List<int> colors) async {
    state = state.copyWith(quickAccessColors: colors);
    await _saveConfig();
  }

  /// Update quick access thicknesses
  Future<void> setQuickAccessThicknesses(List<double> thicknesses) async {
    state = state.copyWith(quickAccessThicknesses: thicknesses);
    await _saveConfig();
  }

  /// Reset to default configuration
  Future<void> resetToDefault() async {
    state = ToolbarConfig.defaultConfig();
    await _saveConfig();
  }

  /// Update entire config (for bulk changes)
  Future<void> updateConfig(ToolbarConfig config) async {
    state = config;
    await _saveConfig();
  }
}

/// Provider for visible tools only (convenience)
final visibleToolsProvider = Provider<List<ToolConfig>>((ref) {
  return ref.watch(toolbarConfigProvider).visibleTools;
});

/// Provider for checking if a specific tool is visible
final isToolVisibleProvider = Provider.family<bool, ToolType>((ref, toolType) {
  final config = ref.watch(toolbarConfigProvider);
  return config.tools
      .firstWhere(
        (t) => t.toolType == toolType,
        orElse: () => ToolConfig(toolType: toolType),
      )
      .isVisible;
});
```

### Test Dosyası: `test/providers/toolbar_config_provider_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/providers/providers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  }

  group('ToolbarConfigNotifier', () {
    test('loads default config when no saved config', () {
      final container = createContainer();
      final config = container.read(toolbarConfigProvider);
      
      expect(config.tools.isNotEmpty, isTrue);
      expect(config.tools.every((t) => t.isVisible), isTrue);
    });

    test('toggleToolVisibility works and persists', () async {
      final container = createContainer();
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      await notifier.toggleToolVisibility(ToolType.eraser);
      
      final config = container.read(toolbarConfigProvider);
      final eraserConfig = config.tools.firstWhere((t) => t.toolType == ToolType.eraser);
      
      expect(eraserConfig.isVisible, isFalse);
      
      // Check persistence
      final savedJson = prefs.getString('starnote_toolbar_config');
      expect(savedJson, isNotNull);
    });

    test('reorderTools works correctly', () async {
      final container = createContainer();
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      final initialFirst = container.read(toolbarConfigProvider).sortedTools.first.toolType;
      
      await notifier.reorderTools(0, 3);
      
      final config = container.read(toolbarConfigProvider);
      expect(config.sortedTools[3].toolType, equals(initialFirst));
    });

    test('resetToDefault restores all tools', () async {
      final container = createContainer();
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      // Make some changes
      await notifier.toggleToolVisibility(ToolType.pen);
      await notifier.toggleToolVisibility(ToolType.eraser);
      
      // Reset
      await notifier.resetToDefault();
      
      final config = container.read(toolbarConfigProvider);
      expect(config.tools.every((t) => t.isVisible), isTrue);
    });

    test('loads saved config on init', () async {
      // Save a config first
      final savedConfig = ToolbarConfig.defaultConfig()
          .toggleToolVisibility(ToolType.shapes);
      await prefs.setString('starnote_toolbar_config', savedConfig.toJsonString());
      
      // Create new container (simulates app restart)
      final container = createContainer();
      final config = container.read(toolbarConfigProvider);
      
      final shapesConfig = config.tools.firstWhere((t) => t.toolType == ToolType.shapes);
      expect(shapesConfig.isVisible, isFalse);
    });
  });

  group('visibleToolsProvider', () {
    test('returns only visible tools', () async {
      final container = createContainer();
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      await notifier.toggleToolVisibility(ToolType.eraser);
      
      final visibleTools = container.read(visibleToolsProvider);
      
      expect(visibleTools.any((t) => t.toolType == ToolType.eraser), isFalse);
    });
  });

  group('isToolVisibleProvider', () {
    test('returns correct visibility', () async {
      final container = createContainer();
      final notifier = container.read(toolbarConfigProvider.notifier);
      
      expect(container.read(isToolVisibleProvider(ToolType.pen)), isTrue);
      
      await notifier.toggleToolVisibility(ToolType.pen);
      
      expect(container.read(isToolVisibleProvider(ToolType.pen)), isFalse);
    });
  });
}
```

### Checklist
```
□ toolbar_config_provider.dart oluşturuldu
□ ToolbarConfigNotifier eklendi
□ SharedPreferences entegrasyonu
□ Persistence çalışıyor
□ toolbar_config_provider_test.dart oluşturuldu
□ Barrel export güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-5: [██____] 2/5)
□ TABLET TESTİ yapıldı
□ Commit: feat(ui): add ToolbarConfigProvider with persistence
```

---

## ADIM 3: Reorderable Tool List Widget (drawing_ui)

### Görev
Sürükle-bırak ile araç sıralama widget'ı

### Dosya: `packages/drawing_ui/lib/src/widgets/reorderable_tool_list.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/toolbar_config.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// A reorderable list of tools for the settings panel.
class ReorderableToolList extends ConsumerWidget {
  const ReorderableToolList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(toolbarConfigProvider);
    final sortedTools = config.sortedTools;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTools.length,
      onReorder: (oldIndex, newIndex) {
        // Adjust for ReorderableListView behavior
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        ref.read(toolbarConfigProvider.notifier).reorderTools(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final toolConfig = sortedTools[index];
        return _ToolListItem(
          key: ValueKey(toolConfig.toolType),
          toolConfig: toolConfig,
          onVisibilityToggle: () {
            ref.read(toolbarConfigProvider.notifier)
                .toggleToolVisibility(toolConfig.toolType);
          },
        );
      },
    );
  }
}

class _ToolListItem extends StatelessWidget {
  const _ToolListItem({
    super.key,
    required this.toolConfig,
    required this.onVisibilityToggle,
  });

  final ToolConfig toolConfig;
  final VoidCallback onVisibilityToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVisible = toolConfig.isVisible;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isVisible ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVisible ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: ReorderableDragStartListener(
          index: toolConfig.order,
          child: Icon(
            Icons.drag_handle,
            color: Colors.grey.shade400,
          ),
        ),
        title: Row(
          children: [
            Icon(
              _getToolIcon(toolConfig.toolType),
              size: 20,
              color: isVisible ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Text(
              _getToolName(toolConfig.toolType),
              style: TextStyle(
                fontSize: 14,
                color: isVisible ? Colors.grey.shade800 : Colors.grey.shade500,
                decoration: isVisible ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
        trailing: Switch(
          value: isVisible,
          onChanged: (_) => onVisibilityToggle(),
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  IconData _getToolIcon(ToolType type) {
    switch (type) {
      case ToolType.pen:
      case ToolType.ballpointPen:
      case ToolType.fountainPen:
        return Icons.edit;
      case ToolType.pencil:
        return Icons.edit_outlined;
      case ToolType.highlighter:
      case ToolType.neonHighlighter:
        return Icons.highlight;
      case ToolType.brush:
        return Icons.brush;
      case ToolType.eraser:
        return Icons.auto_fix_normal;
      case ToolType.lasso:
        return Icons.gesture;
      case ToolType.shapes:
        return Icons.category;
      case ToolType.text:
        return Icons.text_fields;
      case ToolType.image:
        return Icons.image;
      default:
        return Icons.circle;
    }
  }

  String _getToolName(ToolType type) {
    switch (type) {
      case ToolType.pen:
        return 'Kalem';
      case ToolType.pencil:
        return 'Kurşun Kalem';
      case ToolType.ballpointPen:
        return 'Tükenmez Kalem';
      case ToolType.fountainPen:
        return 'Dolma Kalem';
      case ToolType.highlighter:
        return 'Fosforlu Kalem';
      case ToolType.neonHighlighter:
        return 'Neon Fosforlu';
      case ToolType.brush:
        return 'Fırça';
      case ToolType.eraser:
        return 'Silgi';
      case ToolType.lasso:
        return 'Kement';
      case ToolType.shapes:
        return 'Şekiller';
      case ToolType.text:
        return 'Metin';
      case ToolType.image:
        return 'Resim';
      default:
        return type.name;
    }
  }
}
```

### Test Dosyası: `test/widgets/reorderable_tool_list_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/providers/providers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReorderableToolList(),
          ),
        ),
      ),
    );
  }

  testWidgets('displays all tools', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Kalem'), findsOneWidget);
    expect(find.text('Silgi'), findsOneWidget);
  });

  testWidgets('toggle switch works', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find first switch
    final switches = find.byType(Switch);
    expect(switches, findsWidgets);

    // Toggle first switch
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    // Verify state changed (visual feedback)
  });

  testWidgets('shows drag handles', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_handle), findsWidgets);
  });
}
```

### Checklist
```
□ reorderable_tool_list.dart oluşturuldu
□ Sürükle-bırak çalışıyor
□ Visibility toggle çalışıyor
□ Tool ikonları ve isimleri doğru
□ reorderable_tool_list_test.dart oluşturuldu
□ Barrel export güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-5: [███___] 3/5)
□ TABLET TESTİ yapıldı
□ Commit: feat(ui): add ReorderableToolList widget
```

---

## ADIM 4: Toolbar Settings Panel (drawing_ui)

### Görev
Tam özellikli toolbar ayarları paneli

### Dosya: `packages/drawing_ui/lib/src/panels/toolbar_settings_panel.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Panel for customizing toolbar appearance and tool order.
class ToolbarSettingsPanel extends ConsumerWidget {
  const ToolbarSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(toolbarConfigProvider);
    final theme = DrawingTheme.of(context);

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: theme.panelBackground,
        borderRadius: BorderRadius.circular(theme.panelBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context, ref),
          
          const Divider(height: 1),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Access Toggle
                  _buildQuickAccessSection(context, ref, config),
                  
                  const SizedBox(height: 16),
                  
                  // Tools Section
                  _buildToolsSection(context),
                  
                  const SizedBox(height: 16),
                  
                  // Reset Button
                  _buildResetButton(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.settings, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          const Text(
            'Araç Çubuğu Ayarları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              ref.read(activePanelProvider.notifier).state = null;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(
    BuildContext context,
    WidgetRef ref,
    ToolbarConfig config,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hızlı Erişim Çubuğu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: config.showQuickAccess,
                onChanged: (_) {
                  ref.read(toolbarConfigProvider.notifier).toggleQuickAccess();
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
          Text(
            'Sık kullanılan renk ve kalınlıkları göster',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Araçlar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Sıralamak için sürükle',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const ReorderableToolList(),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showResetConfirmation(context, ref),
          icon: const Icon(Icons.restore, size: 18),
          label: const Text('Varsayılana Sıfırla'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sıfırla'),
        content: const Text(
          'Araç çubuğu ayarları varsayılana döndürülecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(toolbarConfigProvider.notifier).resetToDefault();
              Navigator.pop(context);
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}
```

### Test Dosyası: `test/panels/toolbar_settings_panel_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/panels/toolbar_settings_panel.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/providers/providers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ToolbarSettingsPanel(),
          ),
        ),
      ),
    );
  }

  testWidgets('displays header', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Araç Çubuğu Ayarları'), findsOneWidget);
  });

  testWidgets('displays quick access toggle', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Hızlı Erişim Çubuğu'), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
  });

  testWidgets('displays reset button', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Varsayılana Sıfırla'), findsOneWidget);
  });

  testWidgets('reset button shows confirmation dialog', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Varsayılana Sıfırla'));
    await tester.pumpAndSettle();

    expect(find.text('Sıfırla'), findsWidgets); // Dialog title and button
    expect(find.text('İptal'), findsOneWidget);
  });
}
```

### Checklist
```
□ toolbar_settings_panel.dart oluşturuldu/güncellendi
□ Header, quick access toggle, tools section, reset button
□ ReorderableToolList entegrasyonu
□ Reset confirmation dialog
□ toolbar_settings_panel_test.dart oluşturuldu
□ Barrel export güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-5: [████__] 4/5)
□ TABLET TESTİ yapıldı
□ Commit: feat(ui): add complete ToolbarSettingsPanel
```

---

## ADIM 5: Toolbar Integration & Polish

### Görev
Toolbar widget'ını güncelle ve tüm sistemi entegre et

### Dosya Güncellemeleri

#### `packages/drawing_ui/lib/src/widgets/toolbar.dart` (GÜNCELLE)

```dart
// Toolbar build metodunda visibleTools kullan
@override
Widget build(BuildContext context, WidgetRef ref) {
  final visibleTools = ref.watch(visibleToolsProvider);
  final currentTool = ref.watch(currentToolProvider);
  final config = ref.watch(toolbarConfigProvider);
  
  return Container(
    // ... existing container decoration
    child: Row(
      children: [
        // Undo/Redo buttons
        _buildUndoRedoButtons(ref),
        
        const VerticalDivider(width: 1),
        
        // Tool buttons (only visible ones)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: visibleTools.map((toolConfig) {
                return _ToolButton(
                  toolType: toolConfig.toolType,
                  isSelected: currentTool == toolConfig.toolType,
                  onTap: () => _selectTool(ref, toolConfig.toolType),
                  onLongPress: () => _openToolSettings(ref, toolConfig.toolType),
                );
              }).toList(),
            ),
          ),
        ),
        
        const VerticalDivider(width: 1),
        
        // Settings button
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            ref.read(activePanelProvider.notifier).state = PanelType.toolbarSettings;
          },
          tooltip: 'Araç Çubuğu Ayarları',
        ),
        
        // Quick access bar (if enabled)
        if (config.showQuickAccess) ...[
          const VerticalDivider(width: 1),
          _buildQuickAccessBar(ref, config),
        ],
      ],
    ),
  );
}

Widget _buildQuickAccessBar(WidgetRef ref, ToolbarConfig config) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Quick colors
      ...config.quickAccessColors.take(5).map((colorValue) {
        return _QuickColorButton(
          color: Color(colorValue),
          onTap: () => _applyQuickColor(ref, Color(colorValue)),
        );
      }),
      
      const SizedBox(width: 4),
      
      // Quick thicknesses
      ...config.quickAccessThicknesses.take(3).map((thickness) {
        return _QuickThicknessButton(
          thickness: thickness,
          onTap: () => _applyQuickThickness(ref, thickness),
        );
      }),
    ],
  );
}
```

#### `main.dart` (GÜNCELLE - SharedPreferences init)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Final Test Checklist
```
□ Toolbar sadece visible tool'ları gösteriyor
□ Tool sıralaması doğru
□ Settings butonu paneli açıyor
□ Quick access bar toggle çalışıyor
□ Tool visibility toggle çalışıyor (toolbar'dan kayboluyor)
□ Drag-to-reorder çalışıyor
□ Reset varsayılana döndürüyor
□ Ayarlar uygulama yeniden açıldığında korunuyor
□ Performans: UI smooth
□ Regression yok: Tool seçimi, panel açma çalışıyor
```

### Checklist
```
□ toolbar.dart güncellendi (visibleTools kullanıyor)
□ Quick access bar eklendi
□ Settings butonu eklendi
□ main.dart SharedPreferences init
□ Panel açma entegrasyonu
□ Barrel exports güncellendi
□ flutter analyze hata yok
□ flutter test geçiyor
□ CURRENT_STATUS.md güncellendi (4E-5: [██████] 5/5 ✅)
□ CHECKLIST_TODO.md güncellendi
□ TABLET TESTİ yapıldı - TÜM ÖZELLİKLER TEST EDİLDİ
□ Commit: feat(ui): integrate toolbar settings with persistence
□ Final commit: feat: complete Phase 4E-5 Toolbar UX
```

---

## 📋 CURRENT_STATUS.md Güncelleme Şablonu

Her adım sonrası bu formatı kullan:

```markdown
## Quick Status

| Key | Value |
|-----|-------|
| **Current Phase** | 4E - Enhancement & Cleanup |
| **Current Module** | 4E-5 Toolbar UX |
| **Current Step** | X/5 |
| **Last Commit** | [commit message] |
| **Branch** | feature/phase4e-enhancements |

---

## Phase 4E Progress

```
4E-1: Pen Types    [██████] 6/6 ✅
4E-2: Pen Icons    [██████] 6/6 ✅
4E-3: Eraser Modes [██████] 5/5 ✅
4E-4: Color Picker [██████] 6/6 ✅
4E-5: Toolbar UX   [██____] X/5
4E-6: Performance  [______] 0/5
4E-7: Code Quality [______] 0/4
```
```

---

## 📋 CHECKLIST_TODO.md Güncelleme

Phase 4E bölümüne ekle:

```markdown
### Phase 4E-5: Toolbar UX

- [ ] ToolbarConfig model with serialization
- [ ] ToolbarConfigProvider with persistence
- [ ] ReorderableToolList widget
- [ ] ToolbarSettingsPanel complete
- [ ] Toolbar integration with visible tools
- [ ] Quick access bar
- [ ] SharedPreferences init in main
- [ ] All toolbar tests passing
- [ ] Tablet testing complete
```

---

## 🚨 HATIRLATMALAR

1. **Her adım sonrası:** `flutter analyze` ve `flutter test` çalıştır
2. **Commit öncesi:** Tablet/emülatörde manuel test yap
3. **Regression kontrolü:** Tool seçimi, panel açma çalışıyor mu?
4. **SharedPreferences:** main.dart'ta init etmeyi unutma
5. **CURRENT_STATUS.md:** Her adım sonrası güncelle
6. **CHECKLIST:** Tamamlanan maddeleri [x] işaretle

---

*Phase 4E-5 başarıyla tamamlanacak! 🛠️*
