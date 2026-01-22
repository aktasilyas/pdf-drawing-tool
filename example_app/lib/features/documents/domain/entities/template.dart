enum TemplateType {
  blank,
  thinLined,
  thickLined,
  smallGrid,
  largeGrid,
  dotted,
  cornell,
}

class Template {
  final String id;
  final String name;
  final TemplateType type;
  final String? thumbnailAsset;
  final bool isPremium;

  const Template({
    required this.id,
    required this.name,
    required this.type,
    this.thumbnailAsset,
    this.isPremium = false,
  });

  static const List<Template> all = [
    Template(
      id: 'blank',
      name: 'Boş',
      type: TemplateType.blank,
      thumbnailAsset: 'assets/templates/blank.png',
    ),
    Template(
      id: 'thin_lined',
      name: 'İnce Çizgili',
      type: TemplateType.thinLined,
      thumbnailAsset: 'assets/templates/thin_lined.png',
    ),
    Template(
      id: 'thick_lined',
      name: 'Kalın Çizgili',
      type: TemplateType.thickLined,
      thumbnailAsset: 'assets/templates/thick_lined.png',
    ),
    Template(
      id: 'small_grid',
      name: 'Küçük Kareli',
      type: TemplateType.smallGrid,
      thumbnailAsset: 'assets/templates/small_grid.png',
    ),
    Template(
      id: 'large_grid',
      name: 'Büyük Kareli',
      type: TemplateType.largeGrid,
      thumbnailAsset: 'assets/templates/large_grid.png',
    ),
    Template(
      id: 'dotted',
      name: 'Noktalı',
      type: TemplateType.dotted,
      thumbnailAsset: 'assets/templates/dotted.png',
    ),
    Template(
      id: 'cornell',
      name: 'Cornell',
      type: TemplateType.cornell,
      thumbnailAsset: 'assets/templates/cornell.png',
      isPremium: true,
    ),
  ];

  static List<Template> get freeTemplates =>
      all.where((t) => !t.isPremium).toList();

  static List<Template> get premiumTemplates =>
      all.where((t) => t.isPremium).toList();

  static Template? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
