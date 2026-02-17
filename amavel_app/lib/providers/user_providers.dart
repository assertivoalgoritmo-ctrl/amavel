import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amavel_app/domain/models/user_profile.dart';
import 'package:amavel_app/data/repositories/user_repository.dart';
import 'app_providers.dart';

/// Provides a UserRepository instance for user-related operations
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestoreDatasource = ref.watch(firestoreDatasourceProvider);
  final localCache = ref.watch(localCacheProvider);
  return UserRepository(
    firestoreDatasource: firestoreDatasource,
    localCache: localCache,
  );
});

/// Streams the current user's profile from Firestore
/// Returns null if user is not authenticated or profile not found
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider).value;

  if (currentUserId == null) {
    return Stream.value(null);
  }

  return userRepository.watchUserProfile(currentUserId);
});
