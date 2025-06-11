import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupFirebaseAndroid() async {
  // 1. Pedir permisos para Android 13+
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.version.sdkInt >= 33) {
    final status = await Permission.notification.request();
    print('🔔 Permiso de notificación: $status');
  }

  // 2. Solicitar permiso para notificaciones (Firebase)
  await FirebaseMessaging.instance.requestPermission();

  // 3. Crear canal de notificaciones
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel',
    'Notificaciones',
    description: 'Canal por defecto para notificaciones',
    importance: Importance.high,
  );

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImplementation?.createNotificationChannel(channel);

  // 4. Inicializar notificaciones locales
  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 5. Escuchar mensajes en foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🟢 Notificación en foreground: ${message.notification?.title}');
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });
}
