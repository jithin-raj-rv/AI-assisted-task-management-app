import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

enum ConnectivityStatus { online, offline }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get status => _statusController.stream;
  ConnectivityStatus _currentStatus = ConnectivityStatus.offline;

  ConnectivityStatus get currentStatus => _currentStatus;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateStatus(_mapResultToStatus(result));

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _updateStatus(_mapResultToStatus(result));
    });
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);
      print('[Connectivity] Status changed to: $newStatus');
    }
  }

  ConnectivityStatus _mapResultToStatus(List<ConnectivityResult> result) {
    // Consider online if we have any active connection
    // In practice, you might want more sophisticated checking
    // like actually pinging a server
    return result.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn)
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _mapResultToStatus(result) == ConnectivityStatus.online;
  }

  void dispose() {
    _statusController.close();
  }
}
