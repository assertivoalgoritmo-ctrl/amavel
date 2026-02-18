import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/constants.dart';
import 'package:amavel_app/presentation/pages/splash_page.dart';
import 'package:amavel_app/presentation/pages/onboarding/welcome_page.dart';
import 'package:amavel_app/presentation/pages/onboarding/consent_page.dart';
import 'package:amavel_app/presentation/pages/onboarding/voice_setup_page.dart';
import 'package:amavel_app/presentation/pages/main_chat_page.dart';
import 'package:amavel_app/presentation/pages/messages_page.dart';
import 'package:amavel_app/presentation/pages/settings_page.dart';

class AmavelApp extends ConsumerWidget {
  const AmavelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AmavelTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppConstants.routeSplash,
      routes: {
        AppConstants.routeSplash: (_) => const SplashPage(),
        AppConstants.routeOnboarding: (_) => const WelcomePage(),
        AppConstants.routeConsent: (_) => const ConsentPage(),
        AppConstants.routeVoiceSetup: (_) => const VoiceSetupPage(),
        AppConstants.routeHome: (_) => const MainChatPage(),
        AppConstants.routeMessages: (_) => const MessagesPage(),
        AppConstants.routeSettings: (_) => const SettingsPage(),
      },
    );
  }
}
