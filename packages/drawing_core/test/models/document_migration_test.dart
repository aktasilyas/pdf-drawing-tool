import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('DrawingDocument Migration', () {
    test('should load legacy single-layer document', () {
      final legacyJson = {
        'id': 'doc1',
        'title': 'Old Doc',
        'layers': [
          {
            'id': 'l1',
            'name': 'Layer 1',
            'strokes': [],
            'shapes': [],
            'texts': [],
          }
        ],
        'activeLayerIndex': 0,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'width': 595.0,
        'height': 842.0,
      };

      final doc = DrawingDocument.fromJson(legacyJson);
      expect(doc.pages.length, 1);
      expect(doc.pages.first.layers.length, 1);
      expect(doc.pages.first.size.width, 595.0);
      expect(doc.pages.first.size.height, 842.0);
    });

    test('should load legacy document with multiple layers', () {
      final legacyJson = {
        'id': 'doc2',
        'title': 'Multi Layer Doc',
        'layers': [
          {'id': 'l1', 'name': 'Layer 1', 'strokes': [], 'shapes': [], 'texts': []},
          {'id': 'l2', 'name': 'Layer 2', 'strokes': [], 'shapes': [], 'texts': []},
        ],
        'activeLayerIndex': 1,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'width': 1920.0,
        'height': 1080.0,
      };

      final doc = DrawingDocument.fromJson(legacyJson);
      expect(doc.pages.length, 1);
      expect(doc.pages.first.layers.length, 2);
      expect(doc.currentPageIndex, 0);
      expect(doc.activeLayerIndex, 1);
    });

    test('should load v2 multi-page document', () {
      final v2Json = {
        'version': 2,
        'id': 'doc3',
        'title': 'New Doc',
        'pages': [
          {
            'id': 'p1',
            'index': 0,
            'size': {'width': 595.0, 'height': 842.0, 'preset': 'a4Portrait'},
            'background': {'type': 'blank', 'color': 0xFFFFFFFF},
            'layers': [
              {'id': 'l1', 'name': 'Layer 1', 'strokes': [], 'shapes': [], 'texts': []},
            ],
            'createdAt': '2024-01-01T00:00:00.000',
            'updatedAt': '2024-01-01T00:00:00.000',
          }
        ],
        'currentPageIndex': 0,
        'settings': {
          'defaultPageSize': {'width': 595.0, 'height': 842.0, 'preset': 'a4Portrait'},
          'defaultBackground': {'type': 'blank', 'color': 0xFFFFFFFF},
        },
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final doc = DrawingDocument.fromJson(v2Json);
      expect(doc.pages.length, 1);
      expect(doc.currentPageIndex, 0);
      expect(doc.settings, isNotNull);
    });

    test('should export as v2 format', () {
      final doc = DrawingDocument.emptyMultiPage('Test Doc');
      final json = doc.toJson();
      
      expect(json['version'], 2);
      expect(json['pages'], isNotNull);
      expect(json['currentPageIndex'], isNotNull);
      expect(json['settings'], isNotNull);
      expect(json.containsKey('layers'), false); // No legacy field
    });

    test('should support deprecated layers getter', () {
      final doc = DrawingDocument.emptyMultiPage('Test Doc');
      
      // Deprecated but working
      expect(doc.layers, isNotEmpty);
      expect(doc.layers, doc.pages.first.layers);
    });

    test('should support deprecated activeLayerIndex getter', () {
      final doc = DrawingDocument.emptyMultiPage('Test Doc');
      
      // Deprecated but working
      expect(doc.activeLayerIndex, 0);
    });
  });
}
