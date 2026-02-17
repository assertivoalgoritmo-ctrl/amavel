import 'package:flutter/material.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/domain/enums/voice_state.dart';
import 'package:amavel_app/presentation/widgets/animated_orb.dart';
import 'package:amavel_app/presentation/widgets/status_indicator.dart';
import 'package:amavel_app/presentation/widgets/transcript_bubble.dart';
import 'package:amavel_app/presentation/widgets/elder_nav_bar.dart';

class MainChatPage extends StatefulWidget {
  const MainChatPage({Key? key}) : super(key: key);

  @override
  State<MainChatPage> createState() => _MainChatPageState();
}

class _MainChatPageState extends State<MainChatPage> {
  late VoiceState _currentVoiceState;
  String _lastAssistantMessage = 'Olá! Estou aqui para conversar contigo.';
  String _lastUserMessage = '';

  @override
  void initState() {
    super.initState();
    _currentVoiceState = VoiceState.idle;
  }

  void _cycleVoiceState() {
    setState(() {
      switch (_currentVoiceState) {
        case VoiceState.idle:
          _currentVoiceState = VoiceState.listening;
          _lastUserMessage = 'Estou a ouvir...';
          break;
        case VoiceState.listening:
          _currentVoiceState = VoiceState.processing;
          _lastUserMessage = '';
          break;
        case VoiceState.processing:
          _currentVoiceState = VoiceState.speaking;
          _lastAssistantMessage = 'A processar a tua pergunta...';
          break;
        case VoiceState.speaking:
          _currentVoiceState = VoiceState.idle;
          _lastUserMessage = '';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmavelTheme.backgroundColor,
      body: Column(
        children: [
          // Top spacing
          const SizedBox(height: 24),

          // Main content area - scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Orb - Large and centered
                  GestureDetector(
                    onTap: _cycleVoiceState,
                    child: AnimatedOrb(
                      voiceState: _currentVoiceState,
                      size: 280,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Status Indicator
                  StatusIndicator(
                    voiceState: _currentVoiceState,
                  ),
                  const SizedBox(height: 32),

                  // Transcript Bubbles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (_lastUserMessage.isNotEmpty) ...[
                          TranscriptBubble(
                            text: _lastUserMessage,
                            isUserMessage: true,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TranscriptBubble(
                          text: _lastAssistantMessage,
                          isUserMessage: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar
          ElderNavBar(
            currentIndex: 0,
            onIndexChanged: (index) {
              // Navigation handling will be done at the router level
            },
          ),
        ],
      ),
    );
  }
}
