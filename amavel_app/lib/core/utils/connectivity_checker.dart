import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:amavel_app/core/utils/logger.dart';

/// Monitors network connectivity for graceful offline handling.
class ConnectivityChecker {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      final connected = results.any(
        (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile,
      );
      _isConnected = connected;
      return connected;
    });
  }

  /// Check current connectivity
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isConnected = results.any(
        (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile,
      );
      return _isConnected;
    } catch (e) {
      AppLogger.warning('Failed to check connectivity: $e');
      return true; // Assume connected if check fails
    }
  }

  /// Start listening for connectivity changes
  void startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.any(
        (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile,
      );
      _isConnected = connected;
      if (!connected) {
        AppLogger.warning('Network connection lost');
      } else {
        AppLogger.info('Network connection restored');
      }
    });
  }

  /// Stop monitoring
  void dispose() {
    _subscription?.cancel();
  }
}
