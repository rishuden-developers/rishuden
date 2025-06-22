import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'character_question_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _calendarUrlController = TextEditingController();
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

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'calendarUrl': _calendarUrlController.text.trim(),
            }, SetOptions(merge: true));
      }

      await userCredential.user!.sendEmailVerification();
      // メール送信後は認証を促す
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
                  onPressed: () async {
                    await userCredential.user!.reload();
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && user.emailVerified) {
                      Navigator.of(context).pop(); // ダイアログを閉じる
                      // 認証済みなら次の画面へ遷移
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => CharacterQuestionPage(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('まだ認証が完了していません')));
                    }
                  },
                  child: Text('次へ'),
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
      appBar: AppBar(title: Text('アカウント作成')),
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
            TextField(
              controller: _calendarUrlController,
              decoration: InputDecoration(labelText: 'カレンダーURL (.ics形式)'),
              keyboardType: TextInputType.url,
            ),
            if (_error != null) ...[
              SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 24),
            ElevatedButton(child: Text('同意して仮登録'), onPressed: _register),
          ],
        ),
      ),
    );
  }
}
