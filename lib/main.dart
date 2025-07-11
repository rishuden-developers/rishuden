import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'welcome_page.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'main_page.dart';
import 'services/notification_service.dart';
import 'services/background_message_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // バックグラウンド通知ハンドラーを設定
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 通知サービスを初期化
    final notificationService = NotificationService();
    notificationService.setNavigatorKey(navigatorKey);
    await notificationService.initialize();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rishuden',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: AuthWrapper(),
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
