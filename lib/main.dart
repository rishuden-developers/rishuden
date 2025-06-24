import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'main_page.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_page.dart';
import 'user_data_checker.dart';
import 'data_upload_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'json_paste_upload_page.dart'; // ← もう不要なら削除してOK

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
