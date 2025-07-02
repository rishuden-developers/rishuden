import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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
              'profileCompleted': false, // 新規登録時はfalseに設定
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

  Future<void> _openKoan() async {
    const String koanUrl =
        'https://koan.osaka-u.ac.jp/campusweb/campusportal.do?page=main';

    final Uri url = Uri.parse(koanUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('アカウント作成')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: '大学のメールアドレス'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'パスワード'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              Image.asset(
                'assets/calender.png',
                width: 220,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              const Text(
                'KOANの休講・スケジュールを選び、カレンダー連携を選択し、URLを作成を押した後、コピーして、下の入力欄に貼り付けてください。\n例: https://koan.osaka-u.ac.jp/...\n\n※ 新規発行のカレンダーURLは反映まで最大1日程度かかる場合があります。',
                style: TextStyle(fontSize: 13, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _calendarUrlController,
                decoration: InputDecoration(labelText: 'カレンダーURL (.ics形式)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _openKoan,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('KOANを開く'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red)),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                child: Text('同意して仮登録（メールに2段階認証完了通知が送られます）'),
                onPressed: _register,
              ),
            ],
          ),
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
