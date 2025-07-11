import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'character_question_page.dart';
import 'register_page.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  final String universityType;
  const LoginPage({super.key, this.universityType = 'main'});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  Future<void> _login() async {
    setState(() {
      _error = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // メール認証の確認
      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('メール認証が必要です'),
                  content: const Text(
                    '認証メールを送信しました。メール内のリンクをクリックして認証を完了してください。',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await userCredential.user!.sendEmailVerification();
                        if (mounted) Navigator.of(context).pop();
                      },
                      child: const Text('再送信'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
        return;
      }

      // 大学タイプに応じて遷移先を分岐
      if (mounted) {
        if (widget.universityType == 'other') {
          // 他大学の場合は直接メインページへ（キャラクター診断はスキップ）
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPage(universityType: 'other'),
            ),
          );
        } else {
          // 大阪大学の場合はキャラクター診断ページへ
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CharacterQuestionPage()),
          );
        }
      }
    } catch (e) {
      String msg = e.toString();
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          msg = 'ユーザーが見つかりません';
        } else if (e.code == 'wrong-password') {
          msg = 'パスワードが間違っています';
        }
      }
      setState(() {
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.universityType == 'other'
              ? const Color(0xFF8B0000) // 他大学の場合は暗い赤色
              : const Color(0xFF2C3E50), // 大阪大学の場合は暗い青色色調の背景
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // 子要素を水平方向に伸ばす
          children: [
            const SizedBox(height: 100), // 上部の余白
            // 他大学の場合は「開発中」ラベルを表示
            if (widget.universityType == 'other')
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  '開発中',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansJP',
                  ),
                ),
              ),
            // アプリ名
            Text(
              widget.universityType == 'other' ? '履修伝説（他大学版）' : '履修伝説',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // サブタイトル/キャッチフレーズ
            Text(
              widget.universityType == 'other'
                  ? '他大学向けバージョン（開発中）'
                  : 'さあ、冒険を始めよう。',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 64),
            // Email入力フィールド
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'メールアドレス',
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
                labelText: 'パスワード',
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            // SIGN IN ボタン
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.universityType == 'other'
                        ? const Color(0xFFDC143C) // 他大学の場合は赤色
                        : const Color(0xFF3498DB), // 大阪大学の場合は青色基調
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'サインイン',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // アカウントを作成するリンク
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: const Text(
                'アカウントを作成する',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
