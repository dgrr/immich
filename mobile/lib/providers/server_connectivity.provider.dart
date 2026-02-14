import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/api.provider.dart';
import 'package:immich_mobile/services/api.service.dart';
import 'package:logging/logging.dart';

enum ServerConnectivityState {
  connected,
  disconnected,
  checking,
}

class ServerConnectivityNotifier extends StateNotifier<ServerConnectivityState> {
  final ApiService _apiService;
  final _log = Logger('ServerConnectivityNotifier');
  Timer? _pingTimer;
  static const _pingInterval = Duration(seconds: 30);

  ServerConnectivityNotifier(this._apiService) : super(ServerConnectivityState.checking) {
    checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    if (state != ServerConnectivityState.checking) {
      state = ServerConnectivityState.checking;
    }

    try {
      await _apiService.serverInfoApi.pingServer().timeout(const Duration(seconds: 5));
      state = ServerConnectivityState.connected;
      _startPingTimer();
    } catch (e) {
      _log.warning('Server unreachable: $e');
      state = ServerConnectivityState.disconnected;
      _startPingTimer();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) => checkConnectivity());
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }
}

final serverConnectivityProvider =
    StateNotifierProvider<ServerConnectivityNotifier, ServerConnectivityState>((ref) {
  return ServerConnectivityNotifier(ref.watch(apiServiceProvider));
});

final isServerReachableProvider = Provider<bool>((ref) {
  return ref.watch(serverConnectivityProvider) == ServerConnectivityState.connected;
});
