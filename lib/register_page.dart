import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'character_question_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

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
      await userCredential.user!.sendEmailVerification();
      // メール送信後はキャラ診断ページへ遷移せず、認証を促す
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('仮登録完了'),
              content: Text('認証メールを送信しました。メール内のリンクをクリックして本登録を完了してください。'),
              actions: [
                TextButton(
                  onPressed:
                      () async =>
                          await userCredential.user!.sendEmailVerification(),
                  child: Text('再送信'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登録ページ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            if (_error != null) ...[
              SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 24),
            ElevatedButton(child: Text('仮登録'), onPressed: _register),
          ],
        ),
      ),
    );
  }
}
