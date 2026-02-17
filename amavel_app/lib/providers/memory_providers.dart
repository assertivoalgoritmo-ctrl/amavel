import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amavel_app/domain/models/memory_fact.dart';
import 'package:amavel_app/domain/models/user_profile.dart';
import 'package:amavel_app/data/repositories/memory_repository.dart';
import 'package:amavel_app/domain/usecases/memory_manager.dart';
import 'package:amavel_app/services/system_prompt_builder.dart';
import 'app_providers.dart';
import 'user_providers.dart';
import 'voice_providers.dart';

/// Provides a MemoryRepository instance for memory operations
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final firestoreDatasource = ref.watch(firestoreDatasourceProvider);
  final localCache = ref.watch(localCacheProvider);
  return MemoryRepository(
    firestoreDatasource: firestoreDatasource,
    localCache: localCache,
  );
});

/// Provides a MemoryManager instance for managing memory operations
final memoryManagerProvider = Provider<MemoryManager>((ref) {
  final memoryRepository = ref.watch(memoryRepositoryProvider);
  return MemoryManager(memoryRepository: memoryRepository);
});

/// Streams the current user's memory facts from Firestore
/// Automatically handles function calls for adding/updating/deleting memories
final memoryFactsProvider = StreamProvider<List<MemoryFact>>((ref) {
  final memoryRepository = ref.watch(memoryRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider).value;

  if (currentUserId == null) {
    return Stream.value([]);
  }

  return memoryRepository.watchMemoryFacts(currentUserId);
});

/// Builds the current system prompt with memory context
/// This provider combines the system prompt builder with current memory facts
/// to create a complete system prompt for the voice service
final systemPromptProvider = FutureProvider<String>((ref) async {
  final systemPromptBuilder = ref.watch(systemPromptBuilderProvider);
  final memoryFacts = ref.watch(memoryFactsProvider).value ?? [];
  final userProfile = ref.watch(userProfileProvider).value;

  // Build system prompt with memory context
  final systemPrompt = await systemPromptBuilder.buildSystemPrompt(
    memoryFacts: memoryFacts,
    userProfile: userProfile,
  );

  return systemPrompt;
});
