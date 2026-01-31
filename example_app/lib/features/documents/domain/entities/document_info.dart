import 'package:equatable/equatable.dart';
import 'package:drawing_core/drawing_core.dart';

enum SyncState { local, syncing, synced, error }

class DocumentInfo extends Equatable {
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
  final SyncState syncState;
  final String paperColor;
  final bool isPortrait;
  final DocumentType documentType;
  final String? coverId;
  final bool hasCover;
  final double paperWidthMm;
  final double paperHeightMm;

  const DocumentInfo({
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
    this.syncState = SyncState.local,
    this.paperColor = 'Sarı kağıt',
    this.isPortrait = true,
    this.documentType = DocumentType.notebook,
    this.coverId,
    this.hasCover = true,
    this.paperWidthMm = 210.0,
    this.paperHeightMm = 297.0,
  });

  DocumentInfo copyWith({
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
    SyncState? syncState,
    String? paperColor,
    bool? isPortrait,
    DocumentType? documentType,
    String? coverId,
    bool? hasCover,
    double? paperWidthMm,
    double? paperHeightMm,
  }) {
    return DocumentInfo(
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
      paperColor: paperColor ?? this.paperColor,
      isPortrait: isPortrait ?? this.isPortrait,
      documentType: documentType ?? this.documentType,
      coverId: coverId ?? this.coverId,
      hasCover: hasCover ?? this.hasCover,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      paperHeightMm: paperHeightMm ?? this.paperHeightMm,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        folderId,
        templateId,
        createdAt,
        updatedAt,
        thumbnailPath,
        pageCount,
        isFavorite,
        isInTrash,
        syncState,
        paperColor,
        isPortrait,
        documentType,
        coverId,
        hasCover,
        paperWidthMm,
        paperHeightMm,
      ];
}
