import '../../domain/entities/folder.dart';

class FolderModel {
  final String id;
  final String name;
  final String? parentId;
  final int colorValue;
  final DateTime createdAt;
  final int documentCount;

  const FolderModel({
    required this.id,
    required this.name,
    this.parentId,
    this.colorValue = 0xFF2196F3,
    required this.createdAt,
    this.documentCount = 0,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      colorValue: json['color_value'] as int? ?? 0xFF2196F3,
      createdAt: DateTime.parse(json['created_at'] as String),
      documentCount: json['document_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'color_value': colorValue,
        'created_at': createdAt.toIso8601String(),
        'document_count': documentCount,
      };

  Folder toEntity() => Folder(
        id: id,
        name: name,
        parentId: parentId,
        colorValue: colorValue,
        createdAt: createdAt,
        documentCount: documentCount,
      );

  factory FolderModel.fromEntity(Folder entity) => FolderModel(
        id: entity.id,
        name: entity.name,
        parentId: entity.parentId,
        colorValue: entity.colorValue,
        createdAt: entity.createdAt,
        documentCount: entity.documentCount,
      );

  FolderModel copyWith({
    String? id,
    String? name,
    String? parentId,
    int? colorValue,
    DateTime? createdAt,
    int? documentCount,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      documentCount: documentCount ?? this.documentCount,
    );
  }
}
