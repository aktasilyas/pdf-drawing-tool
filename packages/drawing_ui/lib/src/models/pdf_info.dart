/// Information about a PDF document.
class PDFInfo {
  /// Total number of pages in the PDF.
  final int pageCount;

  /// Document title (if available).
  final String? title;

  /// Document author (if available).
  final String? author;

  /// Document subject (if available).
  final String? subject;

  /// Document keywords (if available).
  final String? keywords;

  /// Document creator (if available).
  final String? creator;

  /// Document producer (if available).
  final String? producer;

  /// Creation date (if available).
  final DateTime? creationDate;

  /// Modification date (if available).
  final DateTime? modificationDate;

  /// File size in bytes (if known).
  final int? fileSizeBytes;

  const PDFInfo({
    required this.pageCount,
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
    this.producer,
    this.creationDate,
    this.modificationDate,
    this.fileSizeBytes,
  });

  /// Creates a PDFInfo with only page count (minimal info).
  const PDFInfo.minimal(this.pageCount)
      : title = null,
        author = null,
        subject = null,
        keywords = null,
        creator = null,
        producer = null,
        creationDate = null,
        modificationDate = null,
        fileSizeBytes = null;

  /// Copy with new values.
  PDFInfo copyWith({
    int? pageCount,
    String? title,
    String? author,
    String? subject,
    String? keywords,
    String? creator,
    String? producer,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? fileSizeBytes,
  }) {
    return PDFInfo(
      pageCount: pageCount ?? this.pageCount,
      title: title ?? this.title,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      keywords: keywords ?? this.keywords,
      creator: creator ?? this.creator,
      producer: producer ?? this.producer,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  @override
  String toString() {
    return 'PDFInfo('
        'pageCount: $pageCount, '
        'title: $title, '
        'author: $author)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFInfo &&
          pageCount == other.pageCount &&
          title == other.title &&
          author == other.author &&
          subject == other.subject &&
          keywords == other.keywords &&
          creator == other.creator &&
          producer == other.producer &&
          creationDate == other.creationDate &&
          modificationDate == other.modificationDate &&
          fileSizeBytes == other.fileSizeBytes;

  @override
  int get hashCode => Object.hash(
        pageCount,
        title,
        author,
        subject,
        keywords,
        creator,
        producer,
        creationDate,
        modificationDate,
        fileSizeBytes,
      );
}
