import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PushNotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token;

      try {
        token = await _firebaseMessaging.getToken();
        print('Token FCM: $token');
      } catch (e) {
        print('Error obteniendo token FCM: $e');
        if (kIsWeb) {
          // En web puede fallar por permisos o configuración
          token = null;
        } else {
          rethrow;
        }
      }

      final user = Supabase.instance.client.auth.currentUser;

      if (user != null && token != null) {
        final userData = await Supabase.instance.client
            .from('usuarios')
            .select('perfil, tipo_empleado')
            .eq('id', user.id)
            .maybeSingle();

        if (userData != null) {
          await Supabase.instance.client.from('user_tokens').upsert({
            'usuario_id': user.id,
            'fcm_token': token,
            'perfil': userData['perfil'],
            'tipo_empleado': userData['tipo_empleado'],
          });
        }
      }
    }
  }
}
