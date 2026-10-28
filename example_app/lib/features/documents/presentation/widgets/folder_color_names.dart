/// Localized names for [AppColors.folderColors], by palette index.
library;

import 'package:example_app/l10n/l10n.dart';

/// Returns the screen-reader name of the folder color at [index].
String folderColorName(AppLocalizations l10n, int index) {
  final names = [
    l10n.libraryFolderColorEmerald,
    l10n.libraryFolderColorPurple,
    l10n.libraryFolderColorPink,
    l10n.libraryFolderColorRed,
    l10n.libraryFolderColorOrange,
    l10n.libraryFolderColorAmber,
    l10n.libraryFolderColorGreen,
    l10n.libraryFolderColorTeal,
    l10n.libraryFolderColorCyan,
    l10n.libraryFolderColorBlue,
    l10n.libraryFolderColorGray,
    l10n.libraryFolderColorStone,
  ];
  return names[index];
}
