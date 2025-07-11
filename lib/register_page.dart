import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'character_question_page.dart';
import 'main_page.dart';

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
              'universityType': widget.universityType,
              'universityName':
                  widget.universityType == 'other' ? '他大学' : '大阪大学',
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
                        // 認証済みならメインページへ遷移（キャラクター診断をスキップ）
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder:
                                  (_) => MainPage(
                                    universityType: widget.universityType,
                                  ),
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
      backgroundColor:
          widget.universityType == 'other'
              ? const Color(0xFF8B0000) // 他大学の場合は暗い赤色
              : const Color(0xFF2C3E50), // 大阪大学の場合は暗い青色色調の背景
      appBar: AppBar(
        title: const Text(
          'アカウント作成',
          style: TextStyle(color: Colors.white),
        ), // タイトル色を白に
        backgroundColor:
            widget.universityType == 'other'
                ? const Color(0xFF8B0000) // 他大学の場合は暗い赤色
                : const Color(0xFF2C3E50), // 大阪大学の場合は暗い青色色調の背景
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
                labelText:
                    widget.universityType == 'other'
                        ? 'メールアドレスを入力'
                        : '大学のメールアドレスを入力', // ラベルテキストを簡潔に
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
                child: Text(
                  '利用規約',
                  style: TextStyle(
                    color:
                        widget.universityType == 'other'
                            ? Colors
                                .redAccent // 他大学の場合は赤色
                            : Colors.blueAccent, // 大阪大学の場合は青色
                    decoration: TextDecoration.underline,
                    decorationColor:
                        widget.universityType == 'other'
                            ? Colors
                                .redAccent // 他大学の場合は赤色
                            : Colors.blueAccent, // 大阪大学の場合は青色
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
                  activeColor:
                      widget.universityType == 'other'
                          ? const Color(0xFFDC143C) // 他大学の場合は赤色
                          : const Color(0xFF3498DB), // 大阪大学の場合は青色
                  checkColor: Colors.white,
                ),
                const Text(
                  '利用規約に同意する',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // KOANリンク（他大学の場合は非表示）
            if (widget.universityType != 'other')
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse('https://koan.osaka-u.ac.jp/');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
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

            // カレンダー画像と説明（他大学の場合は非表示）
            if (widget.universityType != 'other') ...[
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
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ), // テキスト色を白に
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),

            // カレンダーURL入力フィールド（他大学の場合は非表示）
            if (widget.universityType != 'other')
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
                        ? (widget.universityType == 'other'
                            ? const Color(0xFFDC143C) // 他大学の場合は赤色
                            : const Color(0xFF3498DB)) // 大阪大学の場合は青色基調
                        : Colors.grey,
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
