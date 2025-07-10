import 'package:flutter/material.dart';
import 'register_page.dart';
import 'login_page.dart';
import 'other_univ_register_page.dart'; // 他大学登録ページを追加

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _onSelectUniversity(BuildContext context, String universityType) async {
    // 大学タイプをProviderやローカルに一時保存（本登録時にFirestoreへ）
    // ここではNavigatorで分岐遷移のみ実装
    if (universityType == 'main') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterPage(universityType: 'main'),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtherUnivRegisterPage()),
      );
    }
  }

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
              'さあ、冒険を始めよう。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70, // 薄い白いテキスト
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 60), // 間隔を調整
            // 大学選択ボタン
            ElevatedButton(
              onPressed: () => _onSelectUniversity(context, 'main'),
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
                '○○大学の方はこちら',
                style: TextStyle(
                  color: Colors.white, // 白いテキスト
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _onSelectUniversity(context, 'other'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '他大学の方はこちら',
                style: TextStyle(
                  color: Colors.white, // 白いテキスト
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
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
