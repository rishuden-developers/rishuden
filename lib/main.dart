import 'dart:math'; // mathライブラリをインポートしてcos, sin関数を使う

import 'package:flutter/material.dart';
import 'login_page.dart';
import 'mail_page.dart';
import 'news_page.dart';
import 'park_page.dart'; // ParkPageは広場画面
import 'character_question_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '履修伝説', // アプリのタイトル
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Material 3 デザインを使用
        // カスタムフォントを使用する場合はここで定義します。
        // 例:
        // fontFamily: 'YourCustomFont',
      ),
      // アプリのホーム画面としてMyHomePageを設定
      home: const MyHomePage(title: '履修伝説 - ホーム'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // --- サイズ比の定義と計算 ---
    // 基準となるボタンの直径 (画面幅の比率)
    final double buttonSize = screenWidth * 0.3; // 例: 画面幅の30%
    final double buttonRadius = buttonSize / 2;

    // キャラクターのサイズ (ボタンの直径に対する比率)
    final double characterSizeRatioToButton = 0.6; // ボタン直径の60%くらいのキャラクター
    final double characterSize = buttonSize * characterSizeRatioToButton;

    // キャラクターの軌道半径 (ボタンの中心からキャラクターの中心までの距離)
    // ボタンの半径 + キャラクターの半径 + ボタンとキャラクターの間の隙間
    // この隙間もボタンの半径に対する比率で設定
    final double gapBetweenButtonAndChar = buttonRadius * 0.2; // ボタン半径の20%
    final double characterOrbitRadius =
        buttonRadius + (characterSize / 2) + gapBetweenButtonAndChar;

    // ドーナツ状の円の半径 (キャラクター軌道の少し外側)
    // ドーナツの半径は、キャラクターの軌道半径 + キャラクターの半径の半分 + ドーナツ線の太さの半分 + 少しの余裕
    final double donutThickness = 50.0; // ドーナツの線の太さ
    final double donutPaddingFromCharOrbit =
        characterSize / 100; // キャラクター軌道からドーナツまでの余裕 (小さくして詰める)
    final double donutRadius =
        characterOrbitRadius + donutPaddingFromCharOrbit + donutThickness / 2;

    // ボタンの中心座標 (画面中央)
    final double buttonCenterX = screenWidth / 2;
    final double buttonCenterY = screenHeight / 2;

    return Scaffold(
      key: _scaffoldKey, // Scaffoldにキーを設定

      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: const Text(
                'メニュー',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('ログイン'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('NEWS'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text('お問い合わせ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MailPage()),
                );
              },
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          // === 1. 背景画像 (最背面で、タップイベントを無視) ===
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                'assets/ranking_guild_background.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey,
                    child: const Center(
                      child: Text(
                        '背景画像を読み込めませんでした',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // === 2. グラデーションオーバーレイ (背景のすぐ上で、タップイベントを無視) ===
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // === 3. アプリのタイトル (手前だが、テキストなのでタップイベントは発生しないが、念のため) ===
          Positioned(
            top: screenHeight * 0.05,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: const Text(
                '履修伝説',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- ここからが変更点：タップしたい要素を後方（手前）に配置 ---

          // === 4. ドーナツ状の円 (キャラクターの周囲、タップイベントを無視) ===
          // ボタンより先に描画されるが、タップは不要なのでIgnorePointer
          Positioned(
            left: (screenWidth / 2) - donutRadius, // ドーナツの中心X
            top: (screenHeight / 2) - donutRadius, // ドーナツの中心Y
            child: IgnorePointer(
              child: Container(
                width: donutRadius * 2, // 直径
                height: donutRadius * 2, // 直径
                decoration: BoxDecoration(
                  shape: BoxShape.circle, // 円形
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4), // 薄い白
                    width: donutThickness, // 太さ
                  ),
                ),
              ),
            ),
          ),

          // === 5. 7体のキャラクター (ドーナツより手前、タップイベントを無視) ===
          // ボタンより先に描画されるが、タップは不要なのでIgnorePointer
          ...List.generate(7, (index) {
            final double angle = 2 * pi * index / 7; // 角度をラジアンで計算 (2*pi = 360度)
            final double charX =
                buttonCenterX +
                characterOrbitRadius * cos(angle) -
                characterSize / 2;
            final double charY =
                buttonCenterY +
                characterOrbitRadius * sin(angle) -
                characterSize / 2;

            List<String> charImagePaths = [
              'assets/character_swordman.png',
              'assets/character_wizard.png',
              'assets/character_merchant.png', // ★修正後のパス★
              'assets/character_adventurer.png',
              'assets/character_gorilla.png',
              'assets/character_takuji.png',
              'assets/character_god.png',
            ];

            if (index < charImagePaths.length) {
              return Positioned(
                left: charX,
                top: charY,
                child: IgnorePointer(
                  // ★キャラクターもタップイベントを無視する★
                  child: Image.asset(
                    charImagePaths[index],
                    width: characterSize,
                    height: characterSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: characterSize,
                        height: characterSize,
                        color: Colors.red.withOpacity(0.5),
                        child: Center(
                          child: Text(
                            '${index + 1}番目のキャラ画像なし',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          // === 6. 丸い「冒険に出る」ボタン (最手前で、タップ可能) ===
          // ここが非常に重要！Stackの最後に近い位置に配置する
          Positioned(
            left: (screenWidth - buttonSize) / 2, // 画面中央に配置
            top: (screenHeight - buttonSize) / 2, // 画面中央に配置
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(buttonRadius), // 円形にする
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.deepOrange.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  print('冒険に出るボタンが押されました！'); // ★確認用のprint★
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ParkPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // 背景はグラデーションを使うため透明に
                  shadowColor: Colors.transparent, // 影を消す
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonRadius),
                  ),
                  padding: EdgeInsets.zero, // Paddingを0にしてContainerに任せる
                ),
                child: const Text(
                  '冒険に出る',
                  textAlign: TextAlign.center, // テキストを中央揃え
                  style: TextStyle(
                    fontSize: 20, // フォントサイズはボタンサイズに合わせて調整
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // === 7. 右上にメニューバーアイコン (最手前) ===
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // ステータスバーの下
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 30),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer(); // 右側のドロワーを開く
              },
            ),
          ),
        ],
      ),
    );
  }
}
