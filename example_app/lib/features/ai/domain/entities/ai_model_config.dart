/// AI provider identifier.
enum AIProvider { openai, google, anthropic }

/// Task types that determine which AI model to use.
enum AITaskType {
  chat,
  mathSimple,
  mathAdvanced,
  ocrSimple,
  ocrComplex,
  summarizeShort,
  summarizeLong,
}

/// Configuration for an AI model selection.
class AIModelConfig {
  final AIProvider provider;
  final String model;
  final int maxTokens;
  final double temperature;

  const AIModelConfig({
    required this.provider,
    required this.model,
    this.maxTokens = 2048,
    this.temperature = 0.7,
  });
}
