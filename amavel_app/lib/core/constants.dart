/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'AMAVEL';
  static const String appVersion = '0.1.0';

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String familyMembersCollection = 'familyMembers';
  static const String memoryFactsCollection = 'memoryFacts';
  static const String conversationsCollection = 'conversations';
  static const String turnsSubcollection = 'turns';
  static const String alertsCollection = 'alerts';
  static const String messagesCollection = 'messages';
  static const String userConsentCollection = 'userConsent';
  static const String appConfigCollection = 'appConfig';

  // Storage paths
  static const String audioStoragePath = 'audio';
  static const String exportsStoragePath = 'exports';

  // SharedPreferences keys
  static const String prefUserId = 'user_id';
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefGdprConsent = 'gdpr_consent';
  static const String prefPipelineMode = 'pipeline_mode';
  static const String prefVoiceSpeed = 'voice_speed';
  static const String prefVoiceVolume = 'voice_volume';

  // Navigation routes
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeConsent = '/consent';
  static const String routeVoiceSetup = '/voice-setup';
  static const String routeHome = '/home';
  static const String routeMessages = '/messages';
  static const String routeSettings = '/settings';

  // Portuguese emergency numbers
  static const String emergencyNumber = '112';
  static const String healthLine = '808 24 24 24';
  static const String healthLineName = 'Linha de Saúde 24';
}
