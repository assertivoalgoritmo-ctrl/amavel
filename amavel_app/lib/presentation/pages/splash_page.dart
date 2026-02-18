import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/constants.dart';
import 'package:amavel_app/domain/enums/voice_state.dart';
import 'package:amavel_app/presentation/widgets/animated_orb.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (mounted) {
      if (onboardingComplete) {
        Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
      } else {
        Navigator.of(context).pushReplacementNamed(AppConstants.routeOnboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmavelTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Orb
            AnimatedOrb(
              state: VoiceState.idle,
              size: 120,
            ),
            const SizedBox(height: 40),
            // Logo Text
            Text(
              'AMAVEL',
              style: const TextStyle(
                color: AmavelTheme.primaryColor,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Tagline
            Text(
              'A sua companheira de confiança',
              style: const TextStyle(
                color: AmavelTheme.textSecondary,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
