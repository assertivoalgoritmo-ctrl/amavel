import 'package:flutter/material.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/domain/enums/voice_state.dart';

/// Shows the current connection and voice status.
/// Uses large, clear text for elderly users.
class StatusIndicator extends StatelessWidget {
  final VoiceState state;
  final bool isConnected;

  const StatusIndicator({
    super.key,
    required this.state,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return _buildIndicator(
        icon: Icons.wifi_off,
        text: 'Sem ligação à internet',
        color: AmavelTheme.errorColor,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        state.portugueseLabel,
        key: ValueKey(state),
        style: TextStyle(
          fontSize: AmavelTheme.textSizeLarge,
          fontWeight: FontWeight.w500,
          color: state == VoiceState.error
              ? AmavelTheme.errorColor
              : AmavelTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: AmavelTheme.textSizeBody,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
