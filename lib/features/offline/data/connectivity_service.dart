import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/offline/connectivity_contract.dart';
import '../../../core/offline/offline_dto.dart';

class ConnectivityService implements ConnectivityContract {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _controller = StreamController<OfflineConnectivityMode>.broadcast();
  OfflineConnectivityMode _mode = OfflineConnectivityMode.online;
  bool _manualOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  OfflineConnectivityMode get currentMode => _mode;

  @override
  Stream<OfflineConnectivityMode> get modeStream => _controller.stream;

  Future<void> initialize() async {
    await _refresh();
    _subscription = _connectivity.onConnectivityChanged.listen(
      (_) => _refresh(),
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  @override
  Future<void> setManualOverride(bool enabled) async {
    _manualOffline = enabled;
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_manualOffline) {
      _emit(OfflineConnectivityMode.offline);
      return;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        _emit(OfflineConnectivityMode.offline);
        return;
      }
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        _emit(OfflineConnectivityMode.online);
        return;
      }
      _emit(OfflineConnectivityMode.degraded);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      _emit(OfflineConnectivityMode.degraded);
    }
  }

  void _emit(OfflineConnectivityMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _controller.add(mode);
  }
}

bool isOnlineMode(OfflineConnectivityMode mode) {
  return mode == OfflineConnectivityMode.online ||
      mode == OfflineConnectivityMode.degraded;
}
