import 'package:flutter/material.dart';
import 'register_page.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50), // 暗い青色色調の背景
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリ名
            const Text(
              '履修伝説',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white, // 白いテキスト
              ),
            ),
            const SizedBox(height: 8),
            // サブタイトル/キャッチフレーズ (ログインページと同じものを追加)
            const Text(
              'Let’s get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70, // 薄い白いテキスト
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 60), // 間隔を調整
            // アカウント作成ボタン
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB), // 青色基調
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'アカウントを作成して冒険を始める',
                style: TextStyle(
                  color: Colors.white, // 白いテキスト
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ログインリンク
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text(
                'すでにアカウントをお持ちの方はこちら (ログイン)',
                style: TextStyle(color: Colors.white70), // 薄い白いテキスト
              ),
            ),
          ],
        ),
      ),
    );
  }
}
