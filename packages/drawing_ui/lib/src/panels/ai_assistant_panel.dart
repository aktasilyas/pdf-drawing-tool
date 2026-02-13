import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// MOCK AI responses for demonstration.
const _mockAIResponses = [
  'This appears to be a flowchart showing a decision process...',
  'The handwritten text reads: "Meeting notes from Tuesday"...',
  'I can help you organize these notes by creating headers and bullet points...',
  'Based on the diagram, it looks like you\'re designing a user flow...',
];

/// Provider for mock AI panel state.
final aiPanelStateProvider = StateProvider<_AIState>((ref) {
  return const _AIState(
    isLoading: false,
    hasSelection: false,
    response: null,
  );
});

class _AIState {
  const _AIState({
    required this.isLoading,
    required this.hasSelection,
    this.response,
  });

  final bool isLoading;
  final bool hasSelection;
  final String? response;

  _AIState copyWith({
    bool? isLoading,
    bool? hasSelection,
    String? response,
  }) {
    return _AIState(
      isLoading: isLoading ?? this.isLoading,
      hasSelection: hasSelection ?? this.hasSelection,
      response: response ?? this.response,
    );
  }
}

/// AI assistant panel for asking questions about selected content.
///
/// This is a MOCK implementation - no real AI integration.
/// All responses are simulated for UI demonstration.
class AIAssistantPanel extends ConsumerStatefulWidget {
  const AIAssistantPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  ConsumerState<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends ConsumerState<AIAssistantPanel> {
  final _questionController = TextEditingController();
  bool _isLoading = false;
  String? _response;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolPanel(
      title: 'Ask AI',
      onClose: widget.onClose,
      headerActions: [
        const _PremiumBadge(),
        const SizedBox(width: 8),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection indicator
          _SelectionIndicator(
            hasSelection: true, // MOCK: Always show as having selection
            selectionDescription: '3 strokes selected', // MOCK
          ),
          const SizedBox(height: 16),

          // Question input
          _QuestionInput(
            controller: _questionController,
            onSubmit: _askAI,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),

          // Quick suggestions
          if (_response == null && !_isLoading) ...[
            PanelSection(
              title: 'SUGGESTIONS',
              child: _QuickSuggestions(
                onSuggestionTap: (suggestion) {
                  _questionController.text = suggestion;
                  _askAI();
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Response area
          if (_isLoading)
            const _LoadingIndicator()
          else if (_response != null)
            _ResponseArea(
              response: _response!,
              onCopy: () => _copyResponse(),
              onRetry: () => _askAI(),
            ),

          const SizedBox(height: 16),

          // Premium notice
          if (_response == null && !_isLoading) const _PremiumNotice(),
        ],
      ),
    );
  }

  void _askAI() {
    if (_questionController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = null;
    });

    // MOCK: Simulate AI response delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Pick a random mock response
          _response = _mockAIResponses[
              DateTime.now().millisecondsSinceEpoch % _mockAIResponses.length];
        });
      }
    });
  }

  void _copyResponse() {
    // MOCK: Would copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// Premium badge indicator.
class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(StarNoteIcons.sparkle, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text(
            'Pro',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows what content is selected for AI context.
class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.hasSelection,
    required this.selectionDescription,
  });

  final bool hasSelection;
  final String selectionDescription;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasSelection 
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasSelection ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            hasSelection ? StarNoteIcons.checkCircle : StarNoteIcons.info,
            size: 20,
            color: hasSelection ? colorScheme.primary : colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasSelection
                  ? selectionDescription
                  : 'Select content to ask AI about',
              style: TextStyle(
                fontSize: 13,
                color: hasSelection ? colorScheme.primary : colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text input for asking questions.
class _QuestionInput extends StatelessWidget {
  const _QuestionInput({
    required this.controller,
    required this.onSubmit,
    required this.isLoading,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Ask a question about your selection...',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 2,
            minLines: 1,
            enabled: !isLoading,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isLoading ? null : onSubmit,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLoading ? colorScheme.outline : colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(
              isLoading ? StarNoteIcons.hourglass : StarNoteIcons.send,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick suggestion chips.
class _QuickSuggestions extends StatelessWidget {
  const _QuickSuggestions({
    required this.onSuggestionTap,
  });

  final ValueChanged<String> onSuggestionTap;

  static const _suggestions = [
    'What does this say?',
    'Summarize this',
    'Explain this diagram',
    'Organize these notes',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.map((suggestion) {
        return GestureDetector(
          onTap: () => onSuggestionTap(suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              suggestion,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Loading indicator while waiting for AI response.
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AI is thinking...',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the AI response.
class _ResponseArea extends StatelessWidget {
  const _ResponseArea({
    required this.response,
    required this.onCopy,
    required this.onRetry,
  });

  final String response;
  final VoidCallback onCopy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(StarNoteIcons.sparkle, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'AI Response',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCopy,
                child: PhosphorIcon(StarNoteIcons.copy, size: 18, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onRetry,
                child: PhosphorIcon(StarNoteIcons.refresh, size: 18, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            response,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notice about premium AI features.
class _PremiumNotice extends StatelessWidget {
  const _PremiumNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          PhosphorIcon(StarNoteIcons.info, size: 18, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI features are limited in free plan. Upgrade for unlimited access.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
