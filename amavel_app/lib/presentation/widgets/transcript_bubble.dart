import 'package:flutter/material.dart';
import 'package:amavel_app/config/theme.dart';

/// Displays the last spoken or heard text in a speech bubble.
/// Uses large, readable text for elderly users.
class TranscriptBubble extends StatelessWidget {
  final String text;
  final bool isAssistant;
  final bool isAnimating;

  const TranscriptBubble({
    super.key,
    required this.text,
    this.isAssistant = false,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: text.isEmpty ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isAssistant
              ? AmavelTheme.primaryColor.withOpacity(0.1)
              : AmavelTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AmavelTheme.borderRadius),
          border: Border.all(
            color: isAssistant
                ? AmavelTheme.primaryColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAssistant) ...[
              Icon(
                Icons.smart_toy_outlined,
                color: AmavelTheme.primaryColor,
                size: AmavelTheme.iconSize,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: AmavelTheme.textSizeBody,
                  color: AmavelTheme.textPrimary,
                  height: 1.5,
                  fontStyle: isAnimating ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
