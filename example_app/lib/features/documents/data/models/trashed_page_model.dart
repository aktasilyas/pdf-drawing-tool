import 'package:example_app/features/documents/domain/entities/trashed_page.dart';

class TrashedPageModel {
  final String id;
  final String pageId;
  final String sourceDocumentId;
  final String sourceDocumentTitle;
  final int originalPageIndex;
  final DateTime deletedAt;
  final Map<String, dynamic> pageData;

  const TrashedPageModel({
    required this.id,
    required this.pageId,
    required this.sourceDocumentId,
    required this.sourceDocumentTitle,
    required this.originalPageIndex,
    required this.deletedAt,
    required this.pageData,
  });

  factory TrashedPageModel.fromJson(Map<String, dynamic> json) {
    return TrashedPageModel(
      id: json['id'] as String,
      pageId: json['page_id'] as String,
      sourceDocumentId: json['source_document_id'] as String,
      sourceDocumentTitle: json['source_document_title'] as String,
      originalPageIndex: json['original_page_index'] as int,
      deletedAt: DateTime.parse(json['deleted_at'] as String),
      pageData: json['page_data'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'page_id': pageId,
        'source_document_id': sourceDocumentId,
        'source_document_title': sourceDocumentTitle,
        'original_page_index': originalPageIndex,
        'deleted_at': deletedAt.toIso8601String(),
        'page_data': pageData,
      };

  TrashedPage toEntity() => TrashedPage(
        id: id,
        pageId: pageId,
        sourceDocumentId: sourceDocumentId,
        sourceDocumentTitle: sourceDocumentTitle,
        originalPageIndex: originalPageIndex,
        deletedAt: deletedAt,
        pageData: pageData,
      );

  factory TrashedPageModel.fromEntity(TrashedPage entity) {
    return TrashedPageModel(
      id: entity.id,
      pageId: entity.pageId,
      sourceDocumentId: entity.sourceDocumentId,
      sourceDocumentTitle: entity.sourceDocumentTitle,
      originalPageIndex: entity.originalPageIndex,
      deletedAt: entity.deletedAt,
      pageData: entity.pageData,
    );
  }
}
