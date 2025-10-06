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
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  static const mainBlue = Color(0xFF2E6DB6);
  static const altRed = Color(0xFFDC143C);

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pw.text.trim(),
      );

      if (!cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('認証メールを送信しました。メール内のリンクで認証してください。')),
        );
        setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      if (widget.universityType == 'other') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainPage(universityType: 'other'),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CharacterQuestionPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'ユーザーが見つかりません',
        'wrong-password' => 'パスワードが間違っています',
        _ => e.message ?? 'サインインに失敗しました',
      };
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.universityType == 'other' ? altRed : mainBlue;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: accent,
        centerTitle: true,
        elevation: 0,
        title: Text(widget.universityType == 'other' ? '履修伝説（他大学版）' : '履修伝説'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // キャッチ最小表示
            Text(
              widget.universityType == 'other'
                  ? '他大学向けバージョン（開発中）'
                  : 'さあ、冒険を始めよう。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // 入力（カードなど使わず最小）
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _input('メールアドレス', Icons.alternate_email),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pw,
              obscureText: _obscure,
              decoration: _input(
                'パスワード',
                Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // サインインボタン（大きめ角丸1つ）
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: accent.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                    _loading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'サインイン',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // 新規作成リンク
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              child: const Text('アカウントを作成する'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: mainBlue, width: 2),
      ),
      fillColor: Colors.grey[50],
      filled: true,
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }
}
