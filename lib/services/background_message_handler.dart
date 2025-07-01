import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// バックグラウンド通知ハンドラー
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase Coreの初期化が必要
  // await Firebase.initializeApp();

  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');

  // バックグラウンドでローカル通知を表示
  await _showBackgroundNotification(message);
}

// バックグラウンドでローカル通知を表示
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    '高優先度通知',
    description: 'クエストやたこ焼きの通知に使用されます',
    importance: Importance.high,
  );

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'high_importance_channel',
        '高優先度通知',
        channelDescription: 'クエストやたこ焼きの通知に使用されます',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? '新しい通知',
    message.notification?.body ?? '',
    platformChannelSpecifics,
    payload: message.data.toString(),
  );
}
