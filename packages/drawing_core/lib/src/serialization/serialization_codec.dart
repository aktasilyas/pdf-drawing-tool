import 'dart:typed_data';
import '../models/drawing_document.dart';

/// Interface for encoding/decoding drawing documents.
///
/// Implement this interface to support different serialization formats
/// (JSON, binary, custom protocols).
///
/// ## Example
///
/// ```dart
/// class JsonCodec implements SerializationCodec {
///   @override
///   Uint8List encode(DrawingDocument document) {
///     final json = jsonEncode(document.toJson());
///     return Uint8List.fromList(utf8.encode(json));
///   }
///
///   @override
///   DrawingDocument decode(Uint8List data) {
///     final json = jsonDecode(utf8.decode(data));
///     return DrawingDocument.fromJson(json);
///   }
/// }
/// ```
abstract class SerializationCodec {
  /// Creates a serialization codec.
  const SerializationCodec();

  /// The format identifier for this codec.
  ///
  /// Used to identify the serialization format in file headers.
  String get formatId;

  /// The file extension associated with this format.
  String get fileExtension;

  /// The MIME type for this format.
  String get mimeType;

  /// Whether this codec supports compression.
  bool get supportsCompression => false;

  /// Encodes a document to bytes.
  Uint8List encode(DrawingDocument document);

  /// Decodes bytes to a document.
  DrawingDocument decode(Uint8List data);

  /// Encodes a document to bytes with optional compression.
  Uint8List encodeCompressed(DrawingDocument document, {int level = 6}) {
    // Default implementation: no compression
    return encode(document);
  }

  /// Decodes potentially compressed bytes to a document.
  DrawingDocument decodeCompressed(Uint8List data) {
    // Default implementation: no decompression
    return decode(data);
  }
}

/// Interface for incremental/streaming serialization.
///
/// Use this for large documents that should be serialized progressively.
abstract class StreamingSerializationCodec extends SerializationCodec {
  /// Starts encoding and returns a stream of chunks.
  Stream<Uint8List> encodeStreaming(DrawingDocument document);

  /// Decodes from a stream of chunks.
  Future<DrawingDocument> decodeStreaming(Stream<Uint8List> data);
}

/// Interface for partial document serialization.
///
/// Use this to serialize only changed portions of a document.
abstract class IncrementalSerializationCodec extends SerializationCodec {
  /// Encodes only the differences between two documents.
  Uint8List encodeDelta(DrawingDocument oldDoc, DrawingDocument newDoc);

  /// Applies a delta to a document.
  DrawingDocument applyDelta(DrawingDocument document, Uint8List delta);
}

/// Metadata about a serialized document.
class SerializationMetadata {
  /// Creates serialization metadata.
  const SerializationMetadata({
    required this.formatId,
    required this.formatVersion,
    this.compressed = false,
    this.createdAt,
    this.checksum,
  });

  /// The format identifier.
  final String formatId;

  /// The format version number.
  final int formatVersion;

  /// Whether the data is compressed.
  final bool compressed;

  /// When the data was serialized.
  final DateTime? createdAt;

  /// Optional checksum for integrity verification.
  final String? checksum;

  /// Converts to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
        'formatId': formatId,
        'formatVersion': formatVersion,
        'compressed': compressed,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (checksum != null) 'checksum': checksum,
      };

  /// Creates from a JSON map.
  factory SerializationMetadata.fromJson(Map<String, dynamic> json) {
    return SerializationMetadata(
      formatId: json['formatId'] as String,
      formatVersion: json['formatVersion'] as int,
      compressed: json['compressed'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      checksum: json['checksum'] as String?,
    );
  }
}

/// Exception thrown when serialization fails.
class SerializationException implements Exception {
  /// Creates a serialization exception.
  const SerializationException(this.message, {this.cause});

  /// A description of the error.
  final String message;

  /// The underlying cause, if any.
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return 'SerializationException: $message (caused by: $cause)';
    }
    return 'SerializationException: $message';
  }
}

/// Exception thrown when deserialization fails.
class DeserializationException implements Exception {
  /// Creates a deserialization exception.
  const DeserializationException(this.message, {this.cause});

  /// A description of the error.
  final String message;

  /// The underlying cause, if any.
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return 'DeserializationException: $message (caused by: $cause)';
    }
    return 'DeserializationException: $message';
  }
}
