import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';

class DocumentModel {
  final String id;
  final String title;
  final String? folderId;
  final String templateId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailPath;
  final int pageCount;
  final bool isFavorite;
  final bool isInTrash;
  final DateTime? deletedAt;
  final int syncState;
  final String paperColor;
  final bool isPortrait;
  final String documentType;
  final String? coverId;
  final bool hasCover;
  final double paperWidthMm;
  final double paperHeightMm;

  const DocumentModel({
    required this.id,
    required this.title,
    this.folderId,
    required this.templateId,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.pageCount = 1,
    this.isFavorite = false,
    this.isInTrash = false,
    this.deletedAt,
    this.syncState = 0,
    this.paperColor = 'Sarı kağıt',
    this.isPortrait = true,
    this.documentType = 'notebook',
    this.coverId,
    this.hasCover = true,
    this.paperWidthMm = 210.0,
    this.paperHeightMm = 297.0,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      folderId: json['folder_id'] as String?,
      templateId: json['template_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      thumbnailPath: json['thumbnail_path'] as String?,
      pageCount: json['page_count'] as int? ?? 1,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isInTrash: json['is_in_trash'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      syncState: json['sync_state'] as int? ?? 0,
      paperColor: json['paper_color'] as String? ?? 'Sarı kağıt',
      isPortrait: json['is_portrait'] as bool? ?? true,
      documentType: json['document_type'] as String? ?? 'notebook',
      coverId: json['cover_id'] as String?,
      hasCover: json['has_cover'] as bool? ?? true,
      paperWidthMm: (json['paper_width_mm'] as num?)?.toDouble() ?? 210.0,
      paperHeightMm: (json['paper_height_mm'] as num?)?.toDouble() ?? 297.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'folder_id': folderId,
        'template_id': templateId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'thumbnail_path': thumbnailPath,
        'page_count': pageCount,
        'is_favorite': isFavorite,
        'is_in_trash': isInTrash,
        'deleted_at': deletedAt?.toIso8601String(),
        'sync_state': syncState,
        'paper_color': paperColor,
        'is_portrait': isPortrait,
        'document_type': documentType,
        'cover_id': coverId,
        'has_cover': hasCover,
        'paper_width_mm': paperWidthMm,
        'paper_height_mm': paperHeightMm,
      };

  /// Convert string to DocumentType enum
  static DocumentType _parseDocumentType(String typeStr) {
    return DocumentType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => DocumentType.notebook,
    );
  }

  DocumentInfo toEntity() => DocumentInfo(
        id: id,
        title: title,
        folderId: folderId,
        templateId: templateId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        thumbnailPath: thumbnailPath,
        pageCount: pageCount,
        isFavorite: isFavorite,
        isInTrash: isInTrash,
        deletedAt: deletedAt,
        syncState: SyncState.values[syncState],
        paperColor: paperColor,
        isPortrait: isPortrait,
        documentType: _parseDocumentType(documentType),
        coverId: coverId,
        hasCover: hasCover,
        paperWidthMm: paperWidthMm,
        paperHeightMm: paperHeightMm,
      );

  factory DocumentModel.fromEntity(DocumentInfo entity) => DocumentModel(
        id: entity.id,
        title: entity.title,
        folderId: entity.folderId,
        templateId: entity.templateId,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        thumbnailPath: entity.thumbnailPath,
        pageCount: entity.pageCount,
        isFavorite: entity.isFavorite,
        isInTrash: entity.isInTrash,
        deletedAt: entity.deletedAt,
        syncState: entity.syncState.index,
        paperColor: entity.paperColor,
        isPortrait: entity.isPortrait,
        documentType: entity.documentType.name,
        coverId: entity.coverId,
        hasCover: entity.hasCover,
        paperWidthMm: entity.paperWidthMm,
        paperHeightMm: entity.paperHeightMm,
      );

  DocumentModel copyWith({
    String? id,
    String? title,
    String? folderId,
    String? templateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
    int? pageCount,
    bool? isFavorite,
    bool? isInTrash,
    DateTime? deletedAt,
    int? syncState,
    String? paperColor,
    bool? isPortrait,
    String? documentType,
    String? coverId,
    bool? hasCover,
    double? paperWidthMm,
    double? paperHeightMm,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      folderId: folderId ?? this.folderId,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      pageCount: pageCount ?? this.pageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isInTrash: isInTrash ?? this.isInTrash,
      deletedAt: deletedAt ?? this.deletedAt,
      syncState: syncState ?? this.syncState,
      paperColor: paperColor ?? this.paperColor,
      isPortrait: isPortrait ?? this.isPortrait,
      documentType: documentType ?? this.documentType,
      coverId: coverId ?? this.coverId,
      hasCover: hasCover ?? this.hasCover,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      paperHeightMm: paperHeightMm ?? this.paperHeightMm,
    );
  }
}
