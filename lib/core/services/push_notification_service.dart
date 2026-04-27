import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_client.dart';
import '../api/api_constants.dart';

// Handler para mensajes en background (debe ser top-level)
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // El sistema operativo muestra la notificación automáticamente en background
}

class PushNotificationService {
  static final _localNotif = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'orquestia_channel',
    'Orquestia',
    description: 'Notificaciones de tareas y procesos',
    importance: Importance.high,
  );

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Mostrar notificaciones cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  static Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await ApiClient().dio.post(
        ApiConstants.deviceToken,
        data: {'token': token},
      );
      // Actualizar token si se renueva
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await ApiClient().dio.post(
          ApiConstants.deviceToken,
          data: {'token': newToken},
        );
      });
    } catch (_) {
      // Si falla el registro no bloqueamos la app
    }
  }
}
