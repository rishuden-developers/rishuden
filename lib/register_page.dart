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
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _calendar = TextEditingController();

  String? _error;
  bool _agree = false;
  bool _loading = false;
  bool _obscure = true;

  static const mainBlue = Color(0xFF2E6DB6);

  Future<void> _register() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pw.text.trim(),
      );

      if (cred.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'universityType': 'main',
              'universityName': '大阪大学',
              'calendarUrl': _calendar.text.trim(),
              'profileCompleted': false,
            }, SetOptions(merge: true));

        await cred.user!.sendEmailVerification();

        if (!mounted) return;
        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('仮登録完了'),
                content: const Text('認証メールを送信しました。リンクをクリックして本登録を完了してください。'),
                actions: [
                  TextButton(
                    onPressed:
                        () async => await cred.user!.sendEmailVerification(),
                    child: const Text('再送信', style: TextStyle(color: mainBlue)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await cred.user!.reload();
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && user.emailVerified) {
                        if (mounted) Navigator.of(context).pop();
                        if (Platform.isAndroid) {
                          final android =
                              FlutterLocalNotificationsPlugin()
                                  .resolvePlatformSpecificImplementation<
                                    AndroidFlutterLocalNotificationsPlugin
                                  >();
                          await android?.requestExactAlarmsPermission();
                        }
                        if (mounted) {
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
                    child: const Text('次へ', style: TextStyle(color: mainBlue)),
                  ),
                ],
              ),
        );
      }
    } on FirebaseAuthException catch (e) {
      var msg = e.message ?? e.code;
      if (e.code == 'email-already-in-use') {
        msg = 'このメールアドレスは既に登録されています';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: mainBlue,
        centerTitle: true,
        elevation: 0,
        title: const Text('アカウント作成'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Text(
              'メール認証後に本登録が完了します',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            // 入力欄（シンプル）
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _input('大学のメールアドレス', Icons.alternate_email),
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

            // 規約と同意
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _agree,
                  activeColor: mainBlue,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                ),
                const Text('利用規約に同意する'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _openUrl('https://example.com/terms'),
                  child: const Text('利用規約を読む'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // KOANリンク（青テキスト）
            Center(
              child: TextButton(
                onPressed: () => _openUrl('https://koan.osaka-u.ac.jp/'),
                child: const Text('KOANにアクセス'),
              ),
            ),

            const SizedBox(height: 8),
            // 説明＋画像
            Column(
              children: [
                Image.asset(
                  'assets/calender.png',
                  width: 320,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                const Text(
                  'KOANの課題ページのURLをコピーして下の入力欄に貼り付けてください。\n'
                  '例: https://koan.osaka-u.ac.jp/... \n\n'
                  '※ 新規発行のカレンダーURLは反映まで最大1日程度かかる場合があります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _calendar,
              keyboardType: TextInputType.url,
              decoration: _input('カレンダーURL (.ics)', Icons.link),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _agree && !_loading ? _register : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainBlue,
                  disabledBackgroundColor: mainBlue.withOpacity(0.4),
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
                          'アカウントを作成する',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
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
      filled: true,
      fillColor: Colors.grey[50],
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
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    _calendar.dispose();
    super.dispose();
  }
}
