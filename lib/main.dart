import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'auth_wrapper.dart';
import 'services/notification_service.dart';
import 'services/background_message_handler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

    // Google Mobile Ads 初期化
    await MobileAds.instance.initialize();
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

