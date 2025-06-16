import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'main_page.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('ja_JP', null);
    runApp(const MyApp());
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
      title: '履修伝説',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'NotoSansJP',
      ),
      home: MyHomePage(title: '履修伝説'),
    );
  }
}
