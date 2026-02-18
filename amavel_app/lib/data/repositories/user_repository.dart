import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amavel_app/domain/models/user_profile.dart';
import 'package:amavel_app/data/datasources/firestore_datasource.dart';

/// Repository for user profile Firestore CRUD operations
class UserRepository {
  final FirestoreDataSource _firestore;

  UserRepository({FirestoreDataSource? firestore})
      : _firestore = firestore ?? FirestoreDataSource();

  /// Gets a user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.userProfileRef.doc(userId).get();

      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar perfil do utilizador: $e');
      rethrow;
    }
  }

  /// Creates a new user profile
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore.userProfileRef.doc(profile.id).set(profile.toJson());
    } catch (e) {
      print('Erro ao criar perfil do utilizador: $e');
      rethrow;
    }
  }

  /// Updates an existing user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore.userProfileRef.doc(profile.id).update({
        'displayName': profile.displayName,
        'dateOfBirth': profile.dateOfBirth != null
            ? Timestamp.fromDate(profile.dateOfBirth!)
            : null,
        'language': profile.language,
        'voicePreferences': profile.voicePreferences.toJson(),
        'familyMemberIds': profile.familyMemberIds,
        'assistantName': profile.assistantName,
        'onboardingCompleted': profile.onboardingCompleted,
        'gdprConsentAt': profile.gdprConsentAt != null
            ? Timestamp.fromDate(profile.gdprConsentAt!)
            : null,
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Erro ao atualizar perfil do utilizador: $e');
      rethrow;
    }
  }

  /// Updates voice preferences for a user
  Future<void> updateVoicePreferences(
    String userId,
    VoicePreferences preferences,
  ) async {
    try {
      await _firestore.userProfileRef.doc(userId).update({
        'voicePreferences': preferences.toJson(),
      });
    } catch (e) {
      print('Erro ao atualizar preferências de voz: $e');
      rethrow;
    }
  }

  /// Marks onboarding as completed
  Future<void> completeOnboarding(String userId) async {
    try {
      await _firestore.userProfileRef.doc(userId).update({
        'onboardingCompleted': true,
      });
    } catch (e) {
      print('Erro ao marcar onboarding como completo: $e');
      rethrow;
    }
  }

  /// Records GDPR consent
  Future<void> recordGdprConsent(String userId) async {
    try {
      await _firestore.userProfileRef.doc(userId).update({
        'gdprConsentAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Erro ao registar consentimento GDPR: $e');
      rethrow;
    }
  }

  /// Updates last active timestamp
  Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.userProfileRef.doc(userId).update({
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Erro ao atualizar último ativo: $e');
      // Don't rethrow - this is not critical
    }
  }

  /// Adds a family member ID to the user's profile
  Future<void> addFamilyMemberId(String userId, String familyMemberId) async {
    try {
      await _firestore.userProfileRef.doc(userId).update({
        'familyMemberIds': FieldValue.arrayUnion([familyMemberId]),
      });
    } catch (e) {
      print('Erro ao adicionar ID de membro da família: $e');
      rethrow;
    }
  }

  /// Removes a family member ID from the user's profile
  Future<void> removeFamilyMemberId(
    String userId,
    String familyMemberId,
  ) async {
    try {
      await _firestore.userProfileRef.doc(userId).update({
        'familyMemberIds': FieldValue.arrayRemove([familyMemberId]),
      });
    } catch (e) {
      print('Erro ao remover ID de membro da família: $e');
      rethrow;
    }
  }

  /// Deletes a user profile (anonymize rather than delete for compliance)
  Future<void> anonymizeUserProfile(String userId) async {
    try {
      await _firestore.userProfileRef.doc(userId).update({
        'displayName': 'Utilizador Anónimo',
        'dateOfBirth': null,
        'familyMemberIds': [],
        'gdprConsentAt': null,
      });
    } catch (e) {
      print('Erro ao anonimizar perfil do utilizador: $e');
      rethrow;
    }
  }

  /// Gets all users (admin only)
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final snapshot = await _firestore.userProfileRef.get();
      return snapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Erro ao recuperar todos os utilizadores: $e');
      rethrow;
    }
  }

  /// Streams user profile changes
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _firestore.userProfileRef.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    });
  }
}
