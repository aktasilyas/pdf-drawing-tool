/// Options for PDF to Page conversion.
class PDFConversionOptions {
  /// Whether to include PDF annotations (not yet implemented).
  final bool includeAnnotations;

  /// Whether to preserve PDF links (not yet implemented).
  final bool preserveLinks;

  /// Whether to embed rendered PDF images as page background.
  final bool embedImages;

  const PDFConversionOptions({
    this.includeAnnotations = false,
    this.preserveLinks = false,
    this.embedImages = true,
  });

  /// Creates a copy with new values.
  PDFConversionOptions copyWith({
    bool? includeAnnotations,
    bool? preserveLinks,
    bool? embedImages,
  }) {
    return PDFConversionOptions(
      includeAnnotations: includeAnnotations ?? this.includeAnnotations,
      preserveLinks: preserveLinks ?? this.preserveLinks,
      embedImages: embedImages ?? this.embedImages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFConversionOptions &&
          includeAnnotations == other.includeAnnotations &&
          preserveLinks == other.preserveLinks &&
          embedImages == other.embedImages;

  @override
  int get hashCode =>
      Object.hash(includeAnnotations, preserveLinks, embedImages);
}
