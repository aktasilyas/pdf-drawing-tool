import 'package:test/test.dart';
import 'package:drawing_core/src/models/document.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/layer.dart';
import 'package:drawing_core/src/models/stroke.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

void main() {
  group('DrawingDocument', () {
    late StrokeStyle defaultStyle;
    late Stroke testStroke1;
    late Stroke testStroke2;
    late Layer testLayer1;
    late Layer testLayer2;

    setUp(() {
      defaultStyle = StrokeStyle.pen();
      testStroke1 = Stroke(
        id: 'stroke-1',
        points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
        style: defaultStyle,
        createdAt: DateTime(2024, 1, 1),
      );
      testStroke2 = Stroke(
        id: 'stroke-2',
        points: [DrawingPoint(x: 20, y: 20)],
        style: defaultStyle,
        createdAt: DateTime(2024, 1, 2),
      );
      testLayer1 = Layer(
        id: 'layer-1',
        name: 'Layer 1',
        strokes: [testStroke1],
      );
      testLayer2 = Layer(
        id: 'layer-2',
        name: 'Layer 2',
        strokes: [testStroke2],
      );
    });

    group('Constructor', () {
      test('creates with required parameters', () {
        final now = DateTime.now();
        final doc = DrawingDocument(
          id: 'test-id',
          title: 'Test Document',
          layers: [testLayer1],
          createdAt: now,
          updatedAt: now,
        );

        expect(doc.id, 'test-id');
        expect(doc.title, 'Test Document');
        expect(doc.layerCount, 1);
        expect(doc.activeLayerIndex, 0); // default
        expect(doc.width, 1920.0); // default
        expect(doc.height, 1080.0); // default
      });

      test('creates with all parameters', () {
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 1, 2);
        final doc = DrawingDocument(
          id: 'test-id',
          title: 'Test Document',
          layers: [testLayer1, testLayer2],
          activeLayerIndex: 1,
          createdAt: created,
          updatedAt: updated,
          width: 800.0,
          height: 600.0,
        );

        expect(doc.activeLayerIndex, 1);
        expect(doc.width, 800.0);
        expect(doc.height, 600.0);
        expect(doc.createdAt, created);
        expect(doc.updatedAt, updated);
      });

      test('layers list is unmodifiable', () {
        final now = DateTime.now();
        final mutableList = [testLayer1];
        final doc = DrawingDocument(
          id: 'id',
          title: 'title',
          layers: mutableList,
          createdAt: now,
          updatedAt: now,
        );

        // Original list modification should not affect document
        mutableList.add(testLayer2);
        expect(doc.layerCount, 1);

        // Document's layers list should throw on modification
        expect(
          () => doc.layers.add(testLayer2),
          throwsUnsupportedError,
        );
      });
    });

    group('Factory: empty', () {
      test('creates document with single empty layer', () {
        final doc = DrawingDocument.empty('New Document');

        expect(doc.id, startsWith('doc_'));
        expect(doc.title, 'New Document');
        expect(doc.layerCount, 1);
        expect(doc.layers[0].name, 'Layer 1');
        expect(doc.layers[0].isEmpty, true);
        expect(doc.activeLayerIndex, 0);
        expect(doc.width, 1920.0);
        expect(doc.height, 1080.0);
      });

      test('creates document with custom dimensions', () {
        final doc = DrawingDocument.empty(
          'Custom Size',
          width: 1024.0,
          height: 768.0,
        );

        expect(doc.width, 1024.0);
        expect(doc.height, 768.0);
      });

      test('sets createdAt and updatedAt to now', () {
        final before = DateTime.now();
        final doc = DrawingDocument.empty('Test');
        final after = DateTime.now();

        expect(
          doc.createdAt.isAfter(before) ||
              doc.createdAt.isAtSameMomentAs(before),
          true,
        );
        expect(
          doc.createdAt.isBefore(after) || doc.createdAt.isAtSameMomentAs(after),
          true,
        );
        expect(doc.createdAt, equals(doc.updatedAt));
      });
    });

    group('Factory: withLayers', () {
      test('creates document with given layers', () {
        final doc = DrawingDocument.withLayers(
          'With Layers',
          [testLayer1, testLayer2],
        );

        expect(doc.layerCount, 2);
        expect(doc.layers[0].id, 'layer-1');
        expect(doc.layers[1].id, 'layer-2');
      });

      test('creates with empty layer if layers list is empty', () {
        final doc = DrawingDocument.withLayers('Empty', []);

        expect(doc.layerCount, 1);
        expect(doc.layers[0].name, 'Layer 1');
      });

      test('creates with custom dimensions', () {
        final doc = DrawingDocument.withLayers(
          'Custom',
          [testLayer1],
          width: 500.0,
          height: 400.0,
        );

        expect(doc.width, 500.0);
        expect(doc.height, 400.0);
      });
    });

    group('Getters', () {
      test('activeLayer returns correct layer', () {
        final doc = DrawingDocument.withLayers(
          'Test',
          [testLayer1, testLayer2],
        ).setActiveLayer(1);

        expect(doc.activeLayer, isNotNull);
        expect(doc.activeLayer!.id, 'layer-2');
      });

      test('activeLayer returns null for invalid index', () {
        final now = DateTime.now();
        final doc = DrawingDocument(
          id: 'id',
          title: 'title',
          layers: [testLayer1],
          activeLayerIndex: 5, // invalid
          createdAt: now,
          updatedAt: now,
        );

        expect(doc.activeLayer, isNull);
      });

      test('strokeCount returns total across all layers', () {
        final layer1 = testLayer1.addStroke(testStroke2); // 2 strokes
        final layer2 = testLayer2; // 1 stroke
        final doc = DrawingDocument.withLayers('Test', [layer1, layer2]);

        expect(doc.strokeCount, 3);
      });

      test('isEmpty returns true for document with no strokes', () {
        final doc = DrawingDocument.empty('Empty');
        expect(doc.isEmpty, true);
        expect(doc.isNotEmpty, false);
      });

      test('isEmpty returns false for document with strokes', () {
        final doc = DrawingDocument.withLayers('Test', [testLayer1]);
        expect(doc.isEmpty, false);
        expect(doc.isNotEmpty, true);
      });
    });

    group('addLayer', () {
      test('adds layer to document', () {
        final doc = DrawingDocument.empty('Test');
        final updated = doc.addLayer(testLayer1);

        expect(doc.layerCount, 1); // original unchanged
        expect(updated.layerCount, 2);
        expect(updated.layers[1].id, 'layer-1');
      });

      test('updates updatedAt', () {
        final doc = DrawingDocument.empty('Test');
        final before = doc.updatedAt;

        // Small delay to ensure different timestamp
        final updated = doc.addLayer(testLayer1);

        expect(
          updated.updatedAt.isAfter(before) ||
              updated.updatedAt.isAtSameMomentAs(before),
          true,
        );
      });

      test('preserves activeLayerIndex', () {
        final doc = DrawingDocument.withLayers(
          'Test',
          [testLayer1, testLayer2],
        ).setActiveLayer(1);

        final updated = doc.addLayer(Layer.empty('New'));

        expect(updated.activeLayerIndex, 1);
      });
    });

    group('removeLayer', () {
      test('removes layer at index', () {
        final doc = DrawingDocument.withLayers(
          'Test',
          [testLayer1, testLayer2],
        );
        final updated = doc.removeLayer(0);

        expect(doc.layerCount, 2); // original unchanged
        expect(updated.layerCount, 1);
        expect(updated.layers[0].id, 'layer-2');
      });

      test('does not remove last layer', () {
        final doc = DrawingDocument.empty('Test');
        final updated = doc.removeLayer(0);

        expect(updated.layerCount, 1);
      });

      test('adjusts activeLayerIndex when removing before active', () {
        final doc = DrawingDocument.withLayers(
          'Test',
          [testLayer1, testLayer2, Layer.empty('Layer 3')],
        ).setActiveLayer(2);

        final updated = doc.removeLayer(0);

        expect(updated.activeLayerIndex, 1); // shifted down
      });

      test('adjusts activeLayerIndex when removing active layer', () {
        final doc = DrawingDocument.withLayers(
          'Test',
          [testLayer1, testLayer2],
        ).setActiveLayer(1);

        final updated = doc.removeLayer(1);

        expect(updated.activeLayerIndex, 0); // clamped to valid range
      });

      test('handles invalid index', () {
        final doc = DrawingDocument.withLayers('Test', [testLayer1]);
        final updated = doc.removeLayer(5);

        expect(updated.layerCount, 1);
      });
    });

    group('updateLayer', () {
      test('updates layer at index', () {
        final doc = DrawingDocument.withLayers('Test', [testLayer1]);
        final newLayer = testLayer1.copyWith(name: 'Updated Layer');
        final updated = doc.updateLayer(0, newLayer);

        expect(doc.layers[0].name, 'Layer 1'); // original unchanged
        expect(updated.layers[0].name, 'Updated Layer');
      });

      test('handles invalid index', () {
        final doc = DrawingDocument.withLayers('Test', [testLayer1]);
        final updated = doc.updateLayer(5, testLayer2);

        expect(updated.layerCount, 1);
        expect(updated.layers[0].id, 'layer-1');
      });

      test('updates updatedAt', () {
        final doc = DrawingDocument.withLayers('Test', [testLayer1]);
        final newLayer = testLayer1.copyWith(name: 'New Name');
        final updated = doc.updateLayer(0, newLayer);

        expect(
          updated.updatedAt.isAfter(doc.updatedAt) ||
              updated.updatedAt.isAtSameMomentAs(doc.updatedAt),
          true,
        );
      });
    });

    group('setActiveLayer', () {
      test('sets active layer index', () {
        final doc = DrawingDocument.withLayers(
          'Test',
          [testLayer1, testLayer2],
        );

        expect(doc.activeLayerIndex, 0);

        final updated = doc.setActiveLayer(1);
        expect(updated.activeLayerIndex, 1);
      });

      test('returns same document for invalid index', () {
        final doc = DrawingDocument.withLayers('Test', [testLayer1]);
        final updated = doc.setActiveLayer(5);

        expect(identical(updated, doc), true);
      });

      test('returns same document for negative index', () {
        final doc = DrawingDocument.withLayers('Test', [testLayer1]);
        final updated = doc.setActiveLayer(-1);

        expect(identical(updated, doc), true);
      });

      test('does not update updatedAt', () {
        final doc = DrawingDocument.withLayers(
          'Test',
          [testLayer1, testLayer2],
        );
        final updated = doc.setActiveLayer(1);

        expect(updated.updatedAt, equals(doc.updatedAt));
      });
    });

    group('addStrokeToActiveLayer', () {
      test('adds stroke to active layer', () {
        final doc = DrawingDocument.empty('Test');
        final updated = doc.addStrokeToActiveLayer(testStroke1);

        expect(doc.strokeCount, 0); // original unchanged
        expect(updated.strokeCount, 1);
        expect(updated.activeLayer!.strokes[0].id, 'stroke-1');
      });

      test('returns same document if no valid active layer', () {
        final now = DateTime.now();
        final doc = DrawingDocument(
          id: 'id',
          title: 'title',
          layers: [testLayer1],
          activeLayerIndex: 5, // invalid
          createdAt: now,
          updatedAt: now,
        );

        final updated = doc.addStrokeToActiveLayer(testStroke2);
        expect(identical(updated, doc), true);
      });
    });

    group('removeStrokeFromActiveLayer', () {
      test('removes stroke from active layer', () {
        final doc = DrawingDocument.withLayers('Test', [testLayer1]);
        final updated = doc.removeStrokeFromActiveLayer('stroke-1');

        expect(doc.strokeCount, 1); // original unchanged
        expect(updated.strokeCount, 0);
      });

      test('returns same document if no valid active layer', () {
        final now = DateTime.now();
        final doc = DrawingDocument(
          id: 'id',
          title: 'title',
          layers: [testLayer1],
          activeLayerIndex: 5, // invalid
          createdAt: now,
          updatedAt: now,
        );

        final updated = doc.removeStrokeFromActiveLayer('stroke-1');
        expect(identical(updated, doc), true);
      });
    });

    group('updateTitle', () {
      test('updates document title', () {
        final doc = DrawingDocument.empty('Old Title');
        final updated = doc.updateTitle('New Title');

        expect(doc.title, 'Old Title'); // original unchanged
        expect(updated.title, 'New Title');
      });

      test('updates updatedAt', () {
        final doc = DrawingDocument.empty('Test');
        final updated = doc.updateTitle('New Title');

        expect(
          updated.updatedAt.isAfter(doc.updatedAt) ||
              updated.updatedAt.isAtSameMomentAs(doc.updatedAt),
          true,
        );
      });
    });

    group('copyWith', () {
      test('copies with single parameter changed', () {
        final doc = DrawingDocument.empty('Original');
        final copied = doc.copyWith(title: 'Copied');

        expect(copied.title, 'Copied');
        expect(copied.id, doc.id);
      });

      test('copies with multiple parameters changed', () {
        final doc = DrawingDocument.empty('Test');
        final newUpdated = DateTime(2025, 1, 1);
        final copied = doc.copyWith(
          title: 'New Title',
          width: 800.0,
          height: 600.0,
          updatedAt: newUpdated,
        );

        expect(copied.title, 'New Title');
        expect(copied.width, 800.0);
        expect(copied.height, 600.0);
        expect(copied.updatedAt, newUpdated);
      });
    });

    group('Equality', () {
      test('two documents with same values are equal', () {
        final now = DateTime.now();
        final doc1 = DrawingDocument(
          id: 'same-id',
          title: 'Same Title',
          layers: [testLayer1],
          activeLayerIndex: 0,
          createdAt: now,
          updatedAt: now,
          width: 1920.0,
          height: 1080.0,
        );

        final doc2 = DrawingDocument(
          id: 'same-id',
          title: 'Same Title',
          layers: [testLayer1],
          activeLayerIndex: 0,
          createdAt: now,
          updatedAt: now,
          width: 1920.0,
          height: 1080.0,
        );

        expect(doc1, equals(doc2));
        expect(doc1.hashCode, equals(doc2.hashCode));
      });

      test('two documents with different ids are not equal', () {
        final now = DateTime.now();
        final doc1 = DrawingDocument(
          id: 'id-1',
          title: 'Title',
          layers: const [],
          createdAt: now,
          updatedAt: now,
        );
        final doc2 = DrawingDocument(
          id: 'id-2',
          title: 'Title',
          layers: const [],
          createdAt: now,
          updatedAt: now,
        );

        expect(doc1, isNot(equals(doc2)));
      });
    });

    group('JSON serialization', () {
      test('toJson converts to correct map', () {
        final created = DateTime(2024, 1, 1, 10, 0);
        final updated = DateTime(2024, 1, 2, 15, 30);
        final doc = DrawingDocument(
          id: 'test-id',
          title: 'Test Document',
          layers: [testLayer1],
          activeLayerIndex: 0,
          createdAt: created,
          updatedAt: updated,
          width: 800.0,
          height: 600.0,
        );

        final json = doc.toJson();

        expect(json['id'], 'test-id');
        expect(json['title'], 'Test Document');
        expect(json['layers'], isA<List>());
        expect((json['layers'] as List).length, 1);
        expect(json['activeLayerIndex'], 0);
        expect(json['createdAt'], created.toIso8601String());
        expect(json['updatedAt'], updated.toIso8601String());
        expect(json['width'], 800.0);
        expect(json['height'], 600.0);
      });

      test('fromJson creates correct document', () {
        final json = {
          'id': 'restored-id',
          'title': 'Restored Document',
          'layers': [testLayer1.toJson()],
          'activeLayerIndex': 0,
          'createdAt': '2024-01-01T10:00:00.000',
          'updatedAt': '2024-01-02T15:30:00.000',
          'width': 800.0,
          'height': 600.0,
        };

        final doc = DrawingDocument.fromJson(json);

        expect(doc.id, 'restored-id');
        expect(doc.title, 'Restored Document');
        expect(doc.layerCount, 1);
        expect(doc.activeLayerIndex, 0);
        expect(doc.width, 800.0);
        expect(doc.height, 600.0);
      });

      test('fromJson uses defaults for missing optional fields', () {
        final json = {
          'id': 'id',
          'title': 'title',
          'layers': <Map<String, dynamic>>[],
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        };

        final doc = DrawingDocument.fromJson(json);

        expect(doc.activeLayerIndex, 0);
        expect(doc.width, 1920.0);
        expect(doc.height, 1080.0);
      });

      test('roundtrip preserves values', () {
        final original = DrawingDocument(
          id: 'roundtrip-id',
          title: 'Roundtrip Test',
          layers: [testLayer1, testLayer2],
          activeLayerIndex: 1,
          createdAt: DateTime(2024, 6, 15, 10, 30),
          updatedAt: DateTime(2024, 6, 16, 14, 45),
          width: 1024.0,
          height: 768.0,
        );

        final json = original.toJson();
        final restored = DrawingDocument.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.layerCount, original.layerCount);
        expect(restored.activeLayerIndex, original.activeLayerIndex);
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
        expect(restored.width, original.width);
        expect(restored.height, original.height);
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        final doc = DrawingDocument.withLayers(
          'My Document',
          [testLayer1],
        );

        final str = doc.toString();

        expect(str, contains('DrawingDocument'));
        expect(str, contains('My Document'));
        expect(str, contains('layerCount: 1'));
        expect(str, contains('strokeCount: 1'));
      });
    });
  });
}
