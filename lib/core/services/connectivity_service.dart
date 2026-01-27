import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionStatusController;

  /// Stream of connection status (true = connected, false = disconnected)
  Stream<bool> get connectionStatus {
    _connectionStatusController ??= StreamController<bool>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _connectionStatusController!.stream;
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = _checkConnectivity(results);
      _connectionStatusController?.add(isConnected);
    });
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  bool _checkConnectivity(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
  }

  /// Check current connection status
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _checkConnectivity(results);
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController?.close();
    _connectionStatusController = null;
  }
}
