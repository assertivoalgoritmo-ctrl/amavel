import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// SharedPreferences wrapper for local caching of user data
class LocalCache {
  static final LocalCache _instance = LocalCache._internal();
  late SharedPreferences _prefs;

  factory LocalCache() {
    return _instance;
  }

  LocalCache._internal();

  /// Initialize the cache
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Stores a string value
  Future<void> setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e) {
      print('Erro ao armazenar valor string: $e');
    }
  }

  /// Retrieves a string value
  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      print('Erro ao recuperar valor string: $e');
      return null;
    }
  }

  /// Stores an integer value
  Future<void> setInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e) {
      print('Erro ao armazenar valor inteiro: $e');
    }
  }

  /// Retrieves an integer value
  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      print('Erro ao recuperar valor inteiro: $e');
      return null;
    }
  }

  /// Stores a boolean value
  Future<void> setBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e) {
      print('Erro ao armazenar valor booleano: $e');
    }
  }

  /// Retrieves a boolean value
  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      print('Erro ao recuperar valor booleano: $e');
      return null;
    }
  }

  /// Stores a double value
  Future<void> setDouble(String key, double value) async {
    try {
      await _prefs.setDouble(key, value);
    } catch (e) {
      print('Erro ao armazenar valor decimal: $e');
    }
  }

  /// Retrieves a double value
  double? getDouble(String key) {
    try {
      return _prefs.getDouble(key);
    } catch (e) {
      print('Erro ao recuperar valor decimal: $e');
      return null;
    }
  }

  /// Stores a list of strings
  Future<void> setStringList(String key, List<String> value) async {
    try {
      await _prefs.setStringList(key, value);
    } catch (e) {
      print('Erro ao armazenar lista de strings: $e');
    }
  }

  /// Retrieves a list of strings
  List<String>? getStringList(String key) {
    try {
      return _prefs.getStringList(key);
    } catch (e) {
      print('Erro ao recuperar lista de strings: $e');
      return null;
    }
  }

  /// Stores a JSON object
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      await _prefs.setString(key, jsonString);
    } catch (e) {
      print('Erro ao armazenar JSON: $e');
    }
  }

  /// Retrieves a JSON object
  Map<String, dynamic>? getJson(String key) {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao recuperar JSON: $e');
      return null;
    }
  }

  /// Stores a JSON array
  Future<void> setJsonArray(String key, List<Map<String, dynamic>> value) async {
    try {
      final jsonString = jsonEncode(value);
      await _prefs.setString(key, jsonString);
    } catch (e) {
      print('Erro ao armazenar array JSON: $e');
    }
  }

  /// Retrieves a JSON array
  List<Map<String, dynamic>>? getJsonArray(String key) {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Erro ao recuperar array JSON: $e');
      return null;
    }
  }

  /// Removes a key from cache
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e) {
      print('Erro ao remover chave do cache: $e');
    }
  }

  /// Clears all cache
  Future<void> clear() async {
    try {
      await _prefs.clear();
    } catch (e) {
      print('Erro ao limpar cache: $e');
    }
  }

  /// Checks if a key exists
  bool containsKey(String key) {
    try {
      return _prefs.containsKey(key);
    } catch (e) {
      print('Erro ao verificar chave: $e');
      return false;
    }
  }

  /// Gets all keys
  Set<String> getKeys() {
    try {
      return _prefs.getKeys();
    } catch (e) {
      print('Erro ao recuperar chaves: $e');
      return {};
    }
  }

  // Cache key constants
  static const String userIdKey = 'user_id';
  static const String userProfileKey = 'user_profile';
  static const String gdprConsentKey = 'gdpr_consent';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String lastSyncKey = 'last_sync_time';
  static const String voicePreferencesKey = 'voice_preferences';
  static const String memoryFactsCacheKey = 'memory_facts_cache';
  static const String conversationsCacheKey = 'conversations_cache';
  static const String appLanguageKey = 'app_language';
  static const String assistantNameKey = 'assistant_name';

  /// Stores user data cache
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    await setJson('cached_user_data', userData);
  }

  /// Retrieves cached user data
  Map<String, dynamic>? getCachedUserData() {
    return getJson('cached_user_data');
  }

  /// Stores the last sync timestamp
  Future<void> recordLastSync() async {
    await setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Gets the last sync timestamp
  DateTime? getLastSync() {
    final timestamp = getInt(lastSyncKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Checks if cache is stale (older than specified duration)
  bool isCacheStale(Duration duration) {
    final lastSync = getLastSync();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > duration;
  }

  /// Stores the current user ID
  Future<void> setCurrentUserId(String userId) async {
    await setString(userIdKey, userId);
  }

  /// Gets the current user ID
  String? getCurrentUserId() {
    return getString(userIdKey);
  }

  /// Clears user-specific data
  Future<void> clearUserData() async {
    await remove(userIdKey);
    await remove(userProfileKey);
    await remove(memoryFactsCacheKey);
    await remove(conversationsCacheKey);
  }
}
