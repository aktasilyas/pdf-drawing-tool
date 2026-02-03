import 'package:equatable/equatable.dart';

class Folder extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final int colorValue;
  final int sortOrder;
  final DateTime createdAt;
  final int documentCount;

  const Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.colorValue = 0xFF2196F3,
    this.sortOrder = 0,
    required this.createdAt,
    this.documentCount = 0,
  });

  /// Bu klasör root klasör mü? (parentId == null)
  bool get isRoot => parentId == null;

  /// Bu klasör alt klasör mü? (parentId != null)
  bool get isSubfolder => parentId != null;

  /// Bu klasörün altına alt klasör eklenebilir mi?
  /// Sadece root klasörlere (parentId == null) eklenebilir.
  /// 2 seviye max kuralı.
  bool get canHaveSubfolders => parentId == null;

  Folder copyWith({
    String? id,
    String? name,
    String? parentId,
    int? colorValue,
    int? sortOrder,
    DateTime? createdAt,
    int? documentCount,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      documentCount: documentCount ?? this.documentCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        parentId,
        colorValue,
        sortOrder,
        createdAt,
        documentCount,
      ];
}
