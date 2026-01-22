import '../../domain/entities/document_info.dart';

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
  final int syncState;

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
    this.syncState = 0,
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
      syncState: json['sync_state'] as int? ?? 0,
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
        'sync_state': syncState,
      };

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
        syncState: SyncState.values[syncState],
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
        syncState: entity.syncState.index,
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
    int? syncState,
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
      syncState: syncState ?? this.syncState,
    );
  }
}
