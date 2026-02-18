import 'package:firebase_auth/firebase_auth.dart';
import 'package:amavel_app/data/repositories/user_repository.dart';
import 'package:amavel_app/domain/models/user_profile.dart';

/// Firebase anonymous authentication service
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository;

  AuthService({
    FirebaseAuth? firebaseAuth,
    required UserRepository userRepository,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _userRepository = userRepository;

  /// Signs in anonymously and returns userId
  Future<String?> signIn() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final userId = userCredential.user?.uid;

      if (userId != null) {
        // Create user profile in Firestore on first sign-in
        final existingProfile = await _userRepository.getUserProfile(userId);

        if (existingProfile == null) {
          final newProfile = UserProfile(
            id: userId,
            displayName: null,
            dateOfBirth: null,
            language: 'pt-PT',
            voicePreferences: VoicePreferences(
              speed: 1.0,
              volume: 1.0,
              voiceGender: 'female',
            ),
            familyMemberIds: [],
            assistantName: 'AMAVEL',
            onboardingCompleted: false,
            gdprConsentAt: null,
            createdAt: DateTime.now(),
            lastActiveAt: DateTime.now(),
          );

          await _userRepository.createUserProfile(newProfile);
        }

        return userId;
      }
    } catch (e) {
      print('Erro ao fazer login anónimo: $e');
      rethrow;
    }

    return null;
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Erro ao fazer logout: $e');
      rethrow;
    }
  }

  /// Gets the current user ID
  String? get currentUserId {
    return _firebaseAuth.currentUser?.uid;
  }

  /// Stream of authentication state changes
  Stream<String?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) => user?.uid);
  }

  /// Gets the current user
  User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  /// Checks if user is authenticated
  bool get isAuthenticated {
    return _firebaseAuth.currentUser != null;
  }
}
