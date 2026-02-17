import 'package:flutter/material.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/constants.dart';
import 'package:amavel_app/domain/enums/voice_state.dart';
import 'package:amavel_app/presentation/widgets/animated_orb.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmavelTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            minHeight: MediaQuery.of(context).size.height,
            children: [
              const SizedBox(height: 40),

              // Top spacing
              Column(
                children: [
                  // Animated Orb
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.05)
                        .animate(_animationController),
                    child: AnimatedOrb(
                      voiceState: VoiceState.idle,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Welcome Text
                  Text(
                    'Olá! Sou a AMAVEL',
                    style: AmavelTheme.displayLarge.copyWith(
                      color: AmavelTheme.primaryColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Estou aqui para lhe fazer companhia. Podemos conversar sobre o que quiser.',
                    style: AmavelTheme.bodyLarge.copyWith(
                      color: AmavelTheme.textColorSecondary,
                      fontSize: 18,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Bottom section with button
              Column(
                children: [
                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AppConstants.consentRoute);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AmavelTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Começar',
                        style: AmavelTheme.headlineSmall.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
