import 'dart:convert';
import 'dart:typed_data';

import '../models/drawing_document.dart';
import 'serialization_codec.dart';

/// JSON-based serialization codec for drawing documents.
///
/// This is the default codec for document persistence.
class JsonDocumentCodec extends SerializationCodec {
  /// Creates a JSON document codec.
  const JsonDocumentCodec();

  @override
  String get formatId => 'starnote.json';

  @override
  String get fileExtension => '.sndoc';

  @override
  String get mimeType => 'application/x-starnote+json';

  @override
  bool get supportsCompression => true;

  @override
  Uint8List encode(DrawingDocument document) {
    try {
      final json = document.toJson();
      final wrapper = {
        'metadata': SerializationMetadata(
          formatId: formatId,
          formatVersion: 1,
          createdAt: DateTime.now(),
        ).toJson(),
        'document': json,
      };
      final jsonString = jsonEncode(wrapper);
      return Uint8List.fromList(utf8.encode(jsonString));
    } catch (e) {
      throw SerializationException('Failed to encode document', cause: e);
    }
  }

  @override
  DrawingDocument decode(Uint8List data) {
    try {
      final jsonString = utf8.decode(data);
      final wrapper = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate metadata
      final metadata =
          SerializationMetadata.fromJson(wrapper['metadata'] as Map<String, dynamic>);
      if (!metadata.formatId.startsWith('starnote')) {
        throw DeserializationException(
          'Unknown format: ${metadata.formatId}',
        );
      }

      return DrawingDocument.fromJson(
        wrapper['document'] as Map<String, dynamic>,
      );
    } catch (e) {
      if (e is DeserializationException) rethrow;
      throw DeserializationException('Failed to decode document', cause: e);
    }
  }

  // TODO: Implement compression using dart:io gzip or a pure Dart alternative
  @override
  Uint8List encodeCompressed(DrawingDocument document, {int level = 6}) {
    // Placeholder: compression not yet implemented
    return encode(document);
  }

  @override
  DrawingDocument decodeCompressed(Uint8List data) {
    // Placeholder: decompression not yet implemented
    return decode(data);
  }
}

/// High-level document serializer with format detection and codec selection.
class DocumentSerializer {
  /// Creates a document serializer.
  DocumentSerializer({
    List<SerializationCodec>? codecs,
  }) : _codecs = {
          for (final codec in codecs ?? [const JsonDocumentCodec()])
            codec.formatId: codec,
        };

  final Map<String, SerializationCodec> _codecs;

  /// The default codec used for serialization.
  SerializationCodec get defaultCodec =>
      _codecs.values.firstWhere((c) => c is JsonDocumentCodec,
          orElse: () => const JsonDocumentCodec());

  /// Registers a codec for use.
  void registerCodec(SerializationCodec codec) {
    _codecs[codec.formatId] = codec;
  }

  /// Serializes a document using the default codec.
  Uint8List serialize(DrawingDocument document, {bool compress = false}) {
    final codec = defaultCodec;
    if (compress && codec.supportsCompression) {
      return codec.encodeCompressed(document);
    }
    return codec.encode(document);
  }

  /// Deserializes a document, auto-detecting the format.
  DrawingDocument deserialize(Uint8List data) {
    // Try to detect format from content
    try {
      final preview = utf8.decode(data.take(100).toList(), allowMalformed: true);
      if (preview.contains('"metadata"') && preview.contains('"formatId"')) {
        // Looks like JSON format
        return const JsonDocumentCodec().decode(data);
      }
    } catch (_) {
      // Not UTF-8, might be binary format
    }

    // Default to JSON codec
    return defaultCodec.decode(data);
  }

  /// Returns the appropriate file extension for the default codec.
  String get fileExtension => defaultCodec.fileExtension;

  /// Returns the MIME type for the default codec.
  String get mimeType => defaultCodec.mimeType;
}

// TODO: Implement BinaryDocumentCodec for more compact storage
// TODO: Implement SVG export codec
// TODO: Implement PNG export codec
