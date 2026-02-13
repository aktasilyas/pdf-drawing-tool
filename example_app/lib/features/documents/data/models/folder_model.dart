import 'package:example_app/features/documents/domain/entities/folder.dart';

class FolderModel {
  final String id;
  final String name;
  final String? parentId;
  final int colorValue;
  final int sortOrder;
  final DateTime createdAt;
  final int documentCount;

  const FolderModel({
    required this.id,
    required this.name,
    this.parentId,
    this.colorValue = 0xFF2196F3,
    this.sortOrder = 0,
    required this.createdAt,
    this.documentCount = 0,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      colorValue: json['color_value'] as int? ?? 0xFF2196F3,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      documentCount: json['document_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'color_value': colorValue,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'document_count': documentCount,
      };

  Folder toEntity() => Folder(
        id: id,
        name: name,
        parentId: parentId,
        colorValue: colorValue,
        sortOrder: sortOrder,
        createdAt: createdAt,
        documentCount: documentCount,
      );

  factory FolderModel.fromEntity(Folder entity) => FolderModel(
        id: entity.id,
        name: entity.name,
        parentId: entity.parentId,
        colorValue: entity.colorValue,
        sortOrder: entity.sortOrder,
        createdAt: entity.createdAt,
        documentCount: entity.documentCount,
      );

  FolderModel copyWith({
    String? id,
    String? name,
    Object? parentId = _sentinel,
    int? colorValue,
    int? sortOrder,
    DateTime? createdAt,
    int? documentCount,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId == _sentinel
          ? this.parentId
          : parentId as String?,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      documentCount: documentCount ?? this.documentCount,
    );
  }

  static const _sentinel = Object();
}
