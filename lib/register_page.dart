import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'character_question_page.dart';
import 'pages/image_timetable_input_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class RegisterPage extends StatefulWidget {
  final String universityType;
  const RegisterPage({Key? key, this.universityType = 'main'})
    : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _calendarUrlController = TextEditingController();
  String? _error;
  bool _agreedToTerms = false; // 利用規約同意フラグ

  Future<void> _register() async {
    setState(() {
      _error = null;
    });
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'universityType': 'main',
              'universityName': '大阪大学',
              'calendarUrl': _calendarUrlController.text.trim(),
              'profileCompleted': false, // 新規登録時はfalseに設定
            }, SetOptions(merge: true));
      }

      await userCredential.user!.sendEmailVerification();
      // メール送信後は認証を促す
      if (mounted) {
        // mounted checkを追加
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text(
                  '仮登録完了',
                  style: TextStyle(color: Colors.black),
                ), // ダイアログタイトル色
                content: const Text(
                  '認証メールを送信しました。メール内のリンクをクリックして本登録を完了してください。',
                  style: TextStyle(color: Colors.black87),
                ), // ダイアログコンテンツ色
                actions: [
                  TextButton(
                    onPressed:
                        () async =>
                            await userCredential.user!.sendEmailVerification(),
                    child: const Text(
                      '再送信',
                      style: TextStyle(color: Color(0xFF3498DB)),
                    ), // ボタン色
                  ),
                  TextButton(
                    onPressed: () async {
                      await userCredential.user!.reload();
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && user.emailVerified) {
                        if (mounted) Navigator.of(context).pop(); // ダイアログを閉じる
                        // 認証済みなら次の画面へ遷移
                        if (mounted) {
                          // Androidの場合のみ正確なアラーム権限を要求
                          if (Platform.isAndroid) {
                            final AndroidFlutterLocalNotificationsPlugin?
                                androidImplementation =
                                FlutterLocalNotificationsPlugin()
                                    .resolvePlatformSpecificImplementation<
                                        AndroidFlutterLocalNotificationsPlugin>();
                            await androidImplementation
                                ?.requestExactAlarmsPermission();
                          }
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => CharacterQuestionPage(),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('まだ認証が完了していません')),
                          );
                        }
                      }
                    },
                    child: const Text(
                      '次へ',
                      style: TextStyle(color: Color(0xFF3498DB)),
                    ), // ボタン色
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      String msg = e.toString();
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        msg = 'このメールアドレスは既に登録されています';
      }
      setState(() {
        _error = msg;
      });
    }
  }

  Future<void> _openKoan() async {
    const String koanUrl =
        'https://koan.osaka-u.ac.jp/campusweb/campusportal.do?page=main';

    final Uri url = Uri.parse(koanUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50), // 暗い青色色調の背景
      appBar: AppBar(
        title: const Text(
          'アカウント作成',
          style: TextStyle(color: Colors.white),
        ), // タイトル色を白に
        backgroundColor: const Color(0xFF2C3E50), // AppBarの背景色を合わせる
        iconTheme: const IconThemeData(color: Colors.white), // 戻るボタンのアイコン色を白に
        elevation: 0, // AppBarの影をなくす
      ),
      body: SingleChildScrollView(
        // スクロール可能にする
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // 子要素を水平方向に伸ばす
          children: [
            const SizedBox(height: 20), // 上部の余白
            // Email入力フィールド
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '大学のメールアドレスを入力', // ラベルテキストを簡潔に
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white54),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // Password入力フィールド
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'パスワードを作成', // ラベルテキストを簡潔に
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white54),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // 利用規約リンク
            Center(
              child: GestureDetector(
                child: const Text(
                  '利用規約',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blueAccent, // 下線を青色に
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 利用規約同意チェックボックス
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (bool? value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF3498DB),
                  checkColor: Colors.white,
                ),
                const Text(
                  '利用規約に同意する',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // KOANリンク
            Center(
              child: GestureDetector(
                onTap: () async {
                  final Uri url = Uri.parse('https://koan.osaka-u.ac.jp/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text(
                  'KOANにアクセス',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blueAccent,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // カレンダー画像と説明
            Center(
              // 画像を中央に配置
              child: Image.asset(
                'assets/calender.png', // assetsフォルダに画像があることを前提
                width: 320, // 280から320にさらに拡大
                height: 150, // 120から150に拡大
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'KOANの課題ページのURLをコピーして、下の入力欄に貼り付けてください。\n例: https://koan.osaka-u.ac.jp/...\n\n※ 新規発行のカレンダーURLは反映まで最大1日程度かかる場合があります。',
              style: TextStyle(fontSize: 13, color: Colors.white70), // テキスト色を白に
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // カレンダーURL入力フィールド
            TextField(
              controller: _calendarUrlController,
              decoration: InputDecoration(
                labelText: 'カレンダーURL (.ics形式)',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white54),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            // 画像から時間割を読み込むUIへの遷移ボタン
            ElevatedButton.icon(
              onPressed: () async {
                // 画像入力UIへ遷移（戻り値で選択画像のパスが返ってくる想定）
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImageTimetableInputUI()),
                );
                // 戻り値はここでは利用せずUIのみ実装する仕様
                if (result == null) {
                  // ユーザーが画像を選択せず戻った場合の処理（UI上で通知）
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('画像が選択されませんでした。')),
                  );
                } else {
                  // 画像パスが返された場合はカレンダーURL欄にそのパスを仮入力する（任意）
                  _calendarUrlController.text = result.toString();
                }
              },
              icon: const Icon(Icons.image),
              label: const Text('画像で時間割を入力'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent), // エラーテキスト色
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // 同意して仮登録ボタン
            ElevatedButton(
              child: const Text(
                'アカウントを作成する',
                style: TextStyle(
                  color: Colors.white, // 白いテキスト
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              onPressed: _agreedToTerms ? _register : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _agreedToTerms
                        ? const Color(0xFF3498DB)
                        : Colors.grey, // 青色基調
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2, // ボタンに少し影を追加
              ),
            ),
            const SizedBox(height: 20), // 下部の余白
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _calendarUrlController.dispose();
    super.dispose();
  }
}
