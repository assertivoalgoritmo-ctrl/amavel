import 'dart:math';
import 'package:flutter/material.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/domain/enums/voice_state.dart';

/// The animated companion orb — AMAVEL's visual representation.
///
/// The orb changes appearance based on the current voice state:
/// - Idle: Gentle, slow breathing pulse in teal
/// - Listening: Faster pulse in deep teal with expanding rings
/// - Thinking: Rotating gradient with orange accent
/// - Speaking: Wave-like motion in sky blue with amplitude response
/// - Error: Red pulse
class AnimatedOrb extends StatefulWidget {
  final VoiceState state;
  final double audioAmplitude; // 0.0 to 1.0
  final double size;
  final VoidCallback? onTap;

  const AnimatedOrb({
    super.key,
    required this.state,
    this.audioAmplitude = 0.0,
    this.size = 200.0,
    this.onTap,
  });

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation (idle + listening)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation (thinking)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Wave animation (speaking)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _waveAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(AnimatedOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    // Stop all animations
    _pulseController.stop();
    _rotationController.stop();
    _waveController.stop();

    switch (widget.state) {
      case VoiceState.idle:
        _pulseController.duration = const Duration(milliseconds: 2500);
        _pulseController.repeat(reverse: true);
        break;

      case VoiceState.listening:
        _pulseController.duration = const Duration(milliseconds: 800);
        _pulseController.repeat(reverse: true);
        break;

      case VoiceState.thinking:
        _rotationController.repeat();
        _pulseController.duration = const Duration(milliseconds: 1500);
        _pulseController.repeat(reverse: true);
        break;

      case VoiceState.speaking:
        _waveController.repeat();
        break;

      case VoiceState.connecting:
        _pulseController.duration = const Duration(milliseconds: 1000);
        _pulseController.repeat(reverse: true);
        break;

      case VoiceState.error:
        _pulseController.duration = const Duration(milliseconds: 500);
        _pulseController.repeat(reverse: true);
        break;
    }
  }

  Color get _primaryColor {
    switch (widget.state) {
      case VoiceState.idle:
        return AmavelTheme.orbIdle;
      case VoiceState.listening:
        return AmavelTheme.orbListening;
      case VoiceState.thinking:
        return AmavelTheme.orbThinking;
      case VoiceState.speaking:
        return AmavelTheme.orbSpeaking;
      case VoiceState.connecting:
        return AmavelTheme.orbIdle.withOpacity(0.6);
      case VoiceState.error:
        return AmavelTheme.orbError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _rotationController,
            _waveController,
          ]),
          builder: (context, child) {
            return CustomPaint(
              painter: _OrbPainter(
                state: widget.state,
                pulseValue: _pulseAnimation.value,
                rotationValue: _rotationAnimation.value,
                waveValue: _waveAnimation.value,
                audioAmplitude: widget.audioAmplitude,
                primaryColor: _primaryColor,
              ),
              size: Size(widget.size, widget.size),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

class _OrbPainter extends CustomPainter {
  final VoiceState state;
  final double pulseValue;
  final double rotationValue;
  final double waveValue;
  final double audioAmplitude;
  final Color primaryColor;

  _OrbPainter({
    required this.state,
    required this.pulseValue,
    required this.rotationValue,
    required this.waveValue,
    required this.audioAmplitude,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw outer glow rings
    _drawGlowRings(canvas, center, maxRadius);

    // Draw main orb
    _drawMainOrb(canvas, center, maxRadius);

    // Draw inner highlight
    _drawInnerHighlight(canvas, center, maxRadius);
  }

  void _drawGlowRings(Canvas canvas, Offset center, double maxRadius) {
    final int ringCount = state == VoiceState.listening ? 3 : 2;
    for (int i = 0; i < ringCount; i++) {
      final ringRadius = maxRadius * (pulseValue + 0.1 * i);
      final opacity = (0.15 - 0.05 * i).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = primaryColor.withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawCircle(center, ringRadius, paint);
    }
  }

  void _drawMainOrb(Canvas canvas, Offset center, double maxRadius) {
    double radius = maxRadius * 0.6;

    switch (state) {
      case VoiceState.idle:
      case VoiceState.connecting:
        radius *= pulseValue;
        break;
      case VoiceState.listening:
        radius *= (pulseValue * 0.9 + audioAmplitude * 0.3).clamp(0.7, 1.2);
        break;
      case VoiceState.thinking:
        radius *= pulseValue;
        break;
      case VoiceState.speaking:
        radius *= (0.85 + audioAmplitude * 0.25);
        break;
      case VoiceState.error:
        radius *= pulseValue;
        break;
    }

    // Gradient for the main orb
    final gradient = RadialGradient(
      colors: [
        primaryColor.withOpacity(0.9),
        primaryColor,
        primaryColor.withOpacity(0.7),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    // For thinking state, add rotation to the gradient
    if (state == VoiceState.thinking) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationValue);
      canvas.translate(-center.dx, -center.dy);
    }

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    // For speaking state, draw with wave distortion
    if (state == VoiceState.speaking) {
      _drawWaveOrb(canvas, center, radius, paint);
    } else {
      canvas.drawCircle(center, radius, paint);
    }

    if (state == VoiceState.thinking) {
      canvas.restore();
    }
  }

  void _drawWaveOrb(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const segments = 64;
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * pi;
      final waveOffset = sin(angle * 4 + waveValue) * audioAmplitude * radius * 0.15;
      final r = radius + waveOffset;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawInnerHighlight(Canvas canvas, Offset center, double maxRadius) {
    final highlightRadius = maxRadius * 0.25 * pulseValue;
    final highlightCenter = Offset(
      center.dx - maxRadius * 0.15,
      center.dy - maxRadius * 0.15,
    );

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(highlightCenter, highlightRadius, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotationValue != rotationValue ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.audioAmplitude != audioAmplitude;
  }
}
