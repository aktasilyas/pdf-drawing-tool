/// Parsed AI response separating content from suggestion chips.
class AIParsedResponse {
  final String content;
  final List<String> suggestions;

  const AIParsedResponse({
    required this.content,
    this.suggestions = const [],
  });

  /// AI yanıtını content ve suggestions olarak ayır.
  factory AIParsedResponse.parse(String rawResponse) {
    const separator = '---suggestions---';
    final index = rawResponse.indexOf(separator);

    if (index == -1) {
      return AIParsedResponse(content: rawResponse.trim());
    }

    final content = rawResponse.substring(0, index).trim();
    final suggestionsRaw = rawResponse.substring(index + separator.length);
    final suggestions = suggestionsRaw
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != '-')
        .toList();

    return AIParsedResponse(content: content, suggestions: suggestions);
  }
}
