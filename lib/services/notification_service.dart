import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:rishuden/attendance_record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // NavigatorKeyを保持するためのフィールド
  GlobalKey<NavigatorState>? _navigatorKey;

  // NavigatorKeyを設定するメソッド
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // 通知チャンネルの設定
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    '高優先度通知',
    description: 'クエストやたこ焼きの通知に使用されます',
    importance: Importance.high,
  );

  // 初期化
  Future<void> initialize() async {
    try {
      // モバイル(Android/iOS)以外では通知関連の初期化をスキップ
      if (!_isAndroidOrIOS) {
        debugPrint('[NotificationService] Skipped initialization on non-mobile platform: '
            '${kIsWeb ? 'web' : defaultTargetPlatform}');
        return;
      }

      // タイムゾーンデータを初期化
      tz.initializeTimeZones();
      // IANAタイムゾーン名でローカルタイムゾーンを設定（例: 日本）
      // Intl.getCurrentLocale() は 'en_US' のようなロケール名を返すため、tz.getLocation には使用しない
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

      // 通知権限を要求
      await _requestPermission();

      // ローカル通知の初期化
      await _initializeLocalNotifications();

      // FCMトークンの取得と保存
      await _getAndSaveFCMToken();

      // 通知ハンドラーの設定
      _setupNotificationHandlers();

      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  // 通知権限を要求
  Future<void> _requestPermission() async {
    if (!_isAndroidOrIOS) return;
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // ローカル通知の初期化
  Future<void> _initializeLocalNotifications() async {
    if (!_isAndroidOrIOS) return;
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Androidチャンネルの作成
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  // FCMトークンの取得と保存
  Future<void> _getAndSaveFCMToken() async {
    try {
      if (!_isAndroidOrIOS) return;
      print('Getting FCM token...');
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveFCMTokenToFirestore(token);
      } else {
        print('FCM token is null');
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // FCMトークンをFirestoreに保存
  Future<void> _saveFCMTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Saving FCM token for user: ${user.uid}');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
        print('FCM token saved to Firestore successfully');
      } else {
        print('No current user found');
      }
    } catch (e) {
      print('Error saving FCM token to Firestore: $e');
    }
  }

  // 通知ハンドラーの設定
  void _setupNotificationHandlers() {
    if (!_isAndroidOrIOS) return;
    // フォアグラウンド通知の処理
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // バックグラウンド通知の処理
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message);
    });

    // アプリが終了状態から起動された場合の処理
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print('App opened from terminated state');
        _handleNotificationTap(message);
      }
    });
  }

  // ローカル通知を表示
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_isAndroidOrIOS) return;
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

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '新しい通知',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // 通知タップ時の処理
  void _onNotificationTapped(NotificationResponse response) {
    if (!_isAndroidOrIOS) return;
    print('Notification tapped: ${response.payload}');
    if (response.payload != null &&
        response.payload!.startsWith('attendance_record:')) {
      final parts = response.payload!.split(':');
      if (parts.length == 4) {
        final subjectName = parts[1];
        final period = parts[2];
        final date = parts[3];
        // NavigatorKeyを使って画面遷移
        if (_navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.push(
            MaterialPageRoute(
              builder:
                  (context) => AttendanceRecordPage(
                    subjectName: subjectName,
                    period: period,
                    date: date,
                  ),
            ),
          );
        }
      }
    }
  }

  // 通知タップ時の処理（FCM）
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // 必要に応じて特定の画面に遷移する処理を追加
  }

  // 手動でローカル通知を表示
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isAndroidOrIOS) return;
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // 同じ授業を取っている人がクエストを作成した時の通知
  Future<void> showNewQuestNotification({
    required String creatorName,
    required String questName,
    required String courseName,
  }) async {
    if (!_isAndroidOrIOS) return;
    await showLocalNotification(
      title: '新しいクエストが作成されました！',
      body: '$creatorName が $courseName で「$questName」クエストを作成しました',
      payload: 'new_quest_created',
    );
  }

  // レビューやクエストでのたこ焼き受信通知
  Future<void> showTakoyakiReceivedNotification({
    required String senderName,
    required String reason,
  }) async {
    if (!_isAndroidOrIOS) return;
    // ローカル通知は自分のデバイスにのみ表示
    await showLocalNotification(
      title: 'たこ焼きを貰いました！',
      body: '$senderName から $reason でたこ焼きを送ってもらいました！',
      payload: 'takoyaki_received',
    );
  }

  // クエスト締め切り1時間前通知
  Future<void> showQuestDeadlineNotification({
    required String questName,
    required String deadline,
  }) async {
    await showLocalNotification(
      title: 'クエスト締め切り間近！',
      body: '「$questName」の締め切りが $deadline です。残り1時間です！',
      payload: 'quest_deadline',
    );
  }

  // 手動でFCMトークンを再取得
  Future<void> refreshFCMToken() async {
    print('Manually refreshing FCM token...');
    if (_isAndroidOrIOS) {
      await _getAndSaveFCMToken();
    }
  }

  // 出席記録通知をスケジューリング
  Future<void> scheduleAttendanceNotification({
    required int id,
    required String subjectName,
    required String period,
    required String date,
    required DateTime endTime,
  }) async {
    if (!_isAndroidOrIOS) return;
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime.from(endTime, tz.local);

    // 授業終了時刻が現在時刻より後の場合のみスケジュール
    if (scheduledTime.isAfter(now)) {
      await _localNotifications.zonedSchedule(
        id,
        '出席を記録しましょう！',
        '${subjectName} (${period}時限) の授業が終わりました。出席を記録しますか？',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'attendance_channel',
            '出席記録通知',
            channelDescription: '授業終了後の出席記録を促す通知',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),

        payload: 'attendance_record:${subjectName}:${period}:${date}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print(
        'Scheduled attendance notification for $subjectName at $scheduledTime',
      );
    }
  }

  // クエスト締切1時間前のローカル通知をスケジューリング
  /*
  Future<void> scheduleQuestDeadlineNotification({
    required String questId,
    required String questName,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    final notificationTime = deadline.subtract(const Duration(hours: 1));
    if (notificationTime.isBefore(now)) return; // 既に過ぎていたらスキップ

    await _localNotifications.zonedSchedule(
      questId.hashCode, // 通知ID
      'クエスト締め切り間近！',
      '「$questName」の締め切りが1時間後です',
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quest_deadline_channel',
          'クエスト締切通知',
          channelDescription: 'クエスト締切1時間前の通知',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // androidAllowWhileIdle: true,
      // uiLocalNotificationDateInterpretation:
      //     UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'quest_deadline',
    );
  }
  */
}

// プラットフォーム判定用の拡張: モバイル(Android/iOS)のみ true
bool get _isAndroidOrIOS => !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
