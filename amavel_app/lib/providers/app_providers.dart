import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amavel_app/services/connectivity_checker.dart';
import 'package:amavel_app/services/auth_service.dart';
import 'package:amavel_app/data/datasources/firestore_datasource.dart';
import 'package:amavel_app/data/local/local_cache.dart';

/// Provides a ConnectivityChecker instance for monitoring network connectivity
final connectivityProvider = Provider<ConnectivityChecker>((ref) {
  return ConnectivityChecker();
});

/// Provides a FirestoreDatasource instance for Firestore operations
final firestoreDatasourceProvider = Provider<FirestoreDatasource>((ref) {
  return FirestoreDatasource();
});

/// Provides a LocalCache instance for local storage operations
final localCacheProvider = Provider<LocalCache>((ref) {
  return LocalCache();
});

/// Provides an AuthService instance for authentication operations
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Streams the current user ID from auth state changes
/// Returns null if user is not authenticated
final currentUserIdProvider = StreamProvider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserIdStream();
});
