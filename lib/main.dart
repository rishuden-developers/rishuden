import 'dart:math'; // mathライブラリをインポートしてcos, sin関数を使う

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'mail_page.dart';
import 'news_page.dart';
import 'park_page.dart';
import 'character_question_page.dart';
import 'user_profile_page.dart';
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
                'assets/stage.png',
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
            top: screenHeight * 0.1, // Y位置は維持 (必要なら調整)
            left: 0,
            right: 0,
            child: IgnorePointer(
              // タップイベントを無視する点は維持
              child: Center(
                // ★ 画像を中央に配置するために Center ウィジェットで囲む (任意)
                child: Image.asset(
                  'assets/title.png', // ★★★ 画像のパスを指定 ★★★
                  height: screenHeight * 0.1, // ★ 画像の高さを指定 (例: 画面高さの10%)
                  // この値はロゴのデザインに合わせて調整してください
                  // widthを指定せず、fit: BoxFit.contain を使うことで
                  // 高さに合わせてアスペクト比を保って幅が決定されます。
                  fit: BoxFit.contain, // アスペクト比を保って領域内に収める
                  errorBuilder: (context, error, stackTrace) {
                    // 画像読み込みエラー時のフォールバック
                    return Container(
                      // エラー時も高さを保つためContainerでラップ
                      height: screenHeight * 0.1,
                      child: const Center(
                        child: Text(
                          'タイトル画像なし',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    );
                  },
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
          Positioned(
            left: (screenWidth - buttonSize) / 2,
            top: (screenHeight - buttonSize) / 2,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(buttonRadius),
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
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  return ElevatedButton(
                    onPressed: () {
                      if (!snapshot.hasData) {
                        // 未ログイン時はログインページへ
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      } else {
                        // ログイン済みの場合は広場画面へ
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const ParkPage(
                                  diagnosedCharacterName: '剣士',
                                  answers: [],
                                  userName: '',
                                ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      !snapshot.hasData ? 'アカウント作成' : '冒険に出る',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
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
                  );
                },
              ),
            ),
          ),

          // === デバッグ用の広場画面遷移ボタン ===
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Opacity(
              opacity: 0.0, // 完全に透明
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    print('Debug button pressed');

                    const String testUserId = 'test_user_001';
                    print('Using test user ID: $testUserId');

                    print('Saving user data to Firestore');
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(testUserId)
                        .set({
                          'character': 'キャラクター1',
                          'characterSelected': true,
                          'name': 'テストユーザー',
                          'grade': '1年',
                          'department': '工学部',
                          'profileCompleted': true,
                        }, SetOptions(merge: true));
                    print('User data saved successfully');

                    if (mounted) {
                      print('Navigating to ParkPage');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ParkPage(
                                diagnosedCharacterName: 'swordman',
                                answers: [],
                                userName: '',
                              ),
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    print('Debug button error: $e');
                    print('Stack trace: $stackTrace');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('エラーが発生しました: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'デバッグ: 広場画面へ',
                  style: TextStyle(fontSize: 14, color: Colors.white),
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

  void _navigateToCharacterQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CharacterQuestionPage()),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const LoginPage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!userSnapshot.hasData) {
              return const LoginPage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

            // キャラクターが選択されていない場合
            if (userData == null || !userData.containsKey('character')) {
              return CharacterQuestionPage();
            }

            // プロフィールが未完了の場合
            if (!userData.containsKey('profileCompleted') ||
                userData['profileCompleted'] != true) {
              return const UserProfilePage();
            }

            // キャラクターが選択されていない場合
            if (userData == null || !userData.containsKey('character')) {
              return CharacterQuestionPage();
            }

            // プロフィールが未完了の場合
            if (!userData.containsKey('profileCompleted') ||
                userData['profileCompleted'] != true) {
              return const UserProfilePage();
            }

            // すべての設定が完了している場合
            return ParkPage(
              diagnosedCharacterName: userData['character'] ?? '剣士',
              answers: [], // 適切な値を設定
              userName: userData['name'] ?? '',
              grade: userData['grade'] ?? '',
              department: userData['department'] ?? '',
            );
          },
        );
      },
    );
  }
}
