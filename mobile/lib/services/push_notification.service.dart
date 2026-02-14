import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/providers/api.provider.dart';
import 'package:immich_mobile/services/api.service.dart';
import 'package:logging/logging.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(apiServiceProvider));
});

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  final log = Logger("PushNotificationService");
  final ApiService _apiService;
  
  FirebaseMessaging? _messaging;
  String? _token;
  String? _sessionId;
  bool _initialized = false;

  PushNotificationService(this._apiService);

  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        log.warning('Push notification permission denied');
        return false;
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      _token = await _messaging!.getToken();
      if (_token != null) {
        log.info('FCM token obtained');
      }

      _messaging!.onTokenRefresh.listen((newToken) {
        _token = newToken;
        _registerTokenWithServer();
      });

      _initialized = true;
      return true;
    } catch (e) {
      log.severe('Failed to initialize push notifications: $e');
      return false;
    }
  }

  Future<void> registerToken(String sessionId) async {
    _sessionId = sessionId;
    
    if (_token == null) {
      log.warning('No FCM token available');
      return;
    }

    try {
      await _apiService.sessionsApi.registerPushToken(sessionId, _token!);
      log.info('Push token registered with server');
    } catch (e) {
      log.severe('Failed to register push token: $e');
    }
  }

  Future<void> _registerTokenWithServer() async {
    if (_sessionId == null || _token == null) return;
    
    try {
      await _apiService.sessionsApi.registerPushToken(_sessionId!, _token!);
      log.info('Push token re-registered after refresh');
    } catch (e) {
      log.severe('Failed to re-register push token: $e');
    }
  }

  void setupForegroundHandler(void Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  void setupNotificationOpenedHandler(void Function(RemoteMessage) onMessageOpened) {
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpened);
  }

  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging?.getInitialMessage();
  }

  String? get token => _token;
  bool get isInitialized => _initialized;
}
