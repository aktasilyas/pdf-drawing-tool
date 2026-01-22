// Free and premium tier limits.
class FreeTierLimits {
  static const int maxDocuments = 5;
  static const int maxFolders = 3;
  static const int maxPagesPerDocument = 10;
  static const bool canUseCloudSync = false;
  static const bool canUsePremiumTemplates = false;
  static const bool canUseAiFeatures = false;
}

class PremiumLimits {
  static const int maxDocuments = -1;
  static const int maxFolders = -1;
  static const int maxPagesPerDocument = -1;
  static const bool canUseCloudSync = true;
  static const bool canUsePremiumTemplates = true;
  static const bool canUseAiFeatures = true;
}
