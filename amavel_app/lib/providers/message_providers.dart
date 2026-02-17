import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amavel_app/domain/models/message.dart';
import 'package:amavel_app/data/repositories/message_repository.dart';
import 'app_providers.dart';

/// Provides a MessageRepository instance for message operations
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final firestoreDatasource = ref.watch(firestoreDatasourceProvider);
  final localCache = ref.watch(localCacheProvider);
  return MessageRepository(
    firestoreDatasource: firestoreDatasource,
    localCache: localCache,
  );
});

/// Streams messages for the current user from Firestore
/// Returns an empty list if user is not authenticated
final messagesProvider = StreamProvider<List<Message>>((ref) {
  final messageRepository = ref.watch(messageRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider).value;

  if (currentUserId == null) {
    return Stream.value([]);
  }

  return messageRepository.watchMessages(currentUserId);
});

/// Computes the count of unread messages for the current user
/// Automatically updates when messages change
final unreadCountProvider = Provider<int>((ref) {
  final messages = ref.watch(messagesProvider).value ?? [];
  return messages.where((message) => !message.isRead).length;
});
