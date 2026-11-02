import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class PushTokenGateway {
  Future<String?> getToken();
}

class FirebasePushTokenGateway implements PushTokenGateway {
  @override
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}

final pushTokenProvider = Provider<PushTokenGateway>(
  (ref) => FirebasePushTokenGateway(),
);

RemoteMessage createDebugMessage(String route) => RemoteMessage(
      messageId: 'debug-${DateTime.now().millisecondsSinceEpoch}',
      notification: const RemoteNotification(
        title: 'Jadwal kuliah berubah',
        body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
      ),
      data: {'route': route, 'id': '3'},
    );
