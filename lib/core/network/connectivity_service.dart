import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Exposes device connectivity as a reactive stream and snapshot.
abstract class ConnectivityService {
  bool get isOnline;
  Stream<bool> get onConnectivityChanged;
}

/// [ConnectivityService] backed by [Connectivity].
class ConnectivityServiceImpl extends GetxService implements ConnectivityService {
  ConnectivityServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final RxBool _isOnline = true.obs;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  bool get isOnline => _isOnline.value;

  @override
  Stream<bool> get onConnectivityChanged => _isOnline.stream;

  /// Initializes connectivity monitoring. Must be called once at startup.
  Future<ConnectivityServiceImpl> init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline.value = _hasConnection(results);
      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        _isOnline.value = _hasConnection(results);
      });
    } on MissingPluginException {
      _isOnline.value = true;
    }
    return this;
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }

  @override
  void onClose() {
    unawaited(_subscription?.cancel());
    super.onClose();
  }
}
