import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // DateFormat を使用するために必要
import 'package:intl/intl.dart'; // DateFormat クラスを使用するために必要
import 'package:firebase_core/firebase_core.dart';
import 'main_page.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_page.dart';
import 'user_data_checker.dart';
<<<<<<< HEAD
import 'data_upload_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
// import 'json_paste_upload_page.dart'; // ← もう不要なら削除してOK
=======
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 出欠を記録するため

// グローバルな通知プラグインインスタンス（main()関数の外に定義）
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// バックグラウンドメッセージハンドラー（トップレベル関数として main() の外に定義）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  if (message.data['type'] == 'attendance_reminder' &&
      message.data.containsKey('classId')) {
    await _showNotificationWithActions(message);
  }
}

// バックグラウンド通知アクションハンドラー（トップレベル関数として定義）
@pragma('vm:entry-point')
Future<void> onDidReceiveBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  print('Background notification action tapped: ${response.actionId}');
  print('Payload: ${response.payload}');
  if (response.actionId != null) {
    await _handleAttendanceAction(response.actionId!, response.payload);
  }
}
>>>>>>> origin/kawak

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ローカル通知の初期化設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          notificationCategories: [
            DarwinNotificationCategory(
              'ATTENDANCE_ACTIONS',
              actions: <DarwinNotificationAction>[
                DarwinNotificationAction.plain(
                  'present_action',
                  '出席',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
                DarwinNotificationAction.plain(
                  'absent_action',
                  '欠席',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.destructive,
                  },
                ),
                DarwinNotificationAction.plain(
                  'late_action',
                  '遅刻',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
              ],
              options: <DarwinNotificationCategoryOption>{
                DarwinNotificationCategoryOption.customDismissAction,
                DarwinNotificationCategoryOption.allowInCarPlay,
              },
            ),
          ],
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notification tapped: ${response.payload}');
        print('Action ID: ${response.actionId}');
        if (response.actionId != null) {
          if (response.actionId == 'present_action' ||
              response.actionId == 'absent_action' ||
              response.actionId == 'late_action') {
            await _handleAttendanceAction(response.actionId!, response.payload);
          } else if (response.actionId == 'Default') {
            // 通知本体がタップされた場合の処理（必要に応じてUI遷移など）
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        await _showNotificationWithActions(message);
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await initializeDateFormatting('ja_JP', null);
    runApp(ProviderScope(child: const MyApp()));
  } catch (e) {
    print('Error initializing app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('アプリの初期化に失敗しました: $e'))),
      ),
    );
  }
}

// ローカル通知を表示するヘルパー関数
Future<void> _showNotificationWithActions(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'attendance_channel',
        '授業出欠通知',
        channelDescription: '授業の出欠を記録するための通知です。',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'present_action',
            '出席',
            cancelNotification: true,
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            'absent_action',
            '欠席',
            cancelNotification: true,
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            'late_action',
            '遅刻',
            cancelNotification: true,
            showsUserInterface: false,
          ),
        ],
      );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(categoryIdentifier: 'ATTENDANCE_ACTIONS');

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    message.messageId.hashCode,
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
    payload: message.data['classId'] ?? 'no_class_id',
  );
}

// 出欠情報をFirestoreに保存する関数
Future<void> _handleAttendanceAction(
  String actionIdentifier,
  String? classId,
) async {
  if (classId == null) {
    print('Error: classId is null.');
    return;
  }

  String status = '';
  if (actionIdentifier == 'present_action') {
    status = 'present';
  } else if (actionIdentifier == 'absent_action') {
    status = 'absent';
  } else if (actionIdentifier == 'late_action') {
    status = 'late';
  } else {
    print('Unknown action: $actionIdentifier');
    return;
  }

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final attendanceDate = DateFormat('yyyyMMdd').format(DateTime.now());
      final attendanceRecordRef = FirebaseFirestore.instance
          .collection('attendance_records')
          .doc(user.uid)
          .collection(classId)
          .doc(attendanceDate);
      final existingRecordDoc = await attendanceRecordRef.get();
      final String? oldStatus = existingRecordDoc.data()?['status'];

      await attendanceRecordRef.set({
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'classId': classId,
        'recordedBy': user.uid,
      }, SetOptions(merge: true));

      print(
        'Attendance recorded: Class $classId, Status $status for user ${user.uid} on $attendanceDate',
      );

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final userDoc = await userDocRef.get();
      Map<String, int> currentAbsenceCount = Map<String, int>.from(
        (userDoc.data()?['absenceCount'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as int),
            ) ??
            {},
      );
      Map<String, int> currentLateCount = Map<String, int>.from(
        (userDoc.data()?['lateCount'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as int),
            ) ??
            {},
      );

      if (oldStatus == 'absent') {
        currentAbsenceCount[classId] = (currentAbsenceCount[classId] ?? 1) - 1;
      } else if (oldStatus == 'late') {
        currentLateCount[classId] = (currentLateCount[classId] ?? 1) - 1;
      }

      if (status == 'absent') {
        currentAbsenceCount[classId] = (currentAbsenceCount[classId] ?? 0) + 1;
      } else if (status == 'late') {
        currentLateCount[classId] = (currentLateCount[classId] ?? 0) + 1;
      }

      currentAbsenceCount[classId] = (currentAbsenceCount[classId] ?? 0).clamp(
        0,
        999999,
      );
      currentLateCount[classId] = (currentLateCount[classId] ?? 0).clamp(
        0,
        999999,
      );

      await userDocRef.set({
        'absenceCount': currentAbsenceCount,
        'lateCount': currentLateCount,
      }, SetOptions(merge: true));

      print('Updated counts in user document.');
    } else {
      print('User not logged in, cannot record attendance.');
    }
  } catch (e) {
    print('Error recording attendance: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rishuden',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: MainPage(), // ← ホーム画面をMainPageに戻す
    );
  }
}

Future<List<Map<String, dynamic>>> fetchCoursesByCategory(
  String category,
) async {
  final query =
      await FirebaseFirestore.instance
          .collection('courses')
          .where('category', isEqualTo: category)
          .get();

  return query.docs.map((doc) => doc.data()).toList();
}

Future<List<Map<String, dynamic>>> fetchCoursesBySubcategory(
  String category,
  String subcategory,
) async {
  final query =
      await FirebaseFirestore.instance
          .collection('courses')
          .where('category', isEqualTo: category)
          .where('subcategory', isEqualTo: subcategory)
          .get();

  return query.docs.map((doc) => doc.data()).toList();
}

class CourseListPage extends StatefulWidget {
  final String category;
  CourseListPage({required this.category});

  @override
  _CourseListPageState createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = fetchCoursesByCategory(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('データがありません'));
          }
          final courses = snapshot.data!;
          return ListView(
            children:
                courses
                    .map(
                      (course) => ListTile(
                        title: Text(course['name'] ?? ''),
                        subtitle: Text(
                          course['instructor'] ?? course['teacher'] ?? '',
                        ),
                      ),
                    )
                    .toList(),
          );
        },
      ),
    );
  }
}
