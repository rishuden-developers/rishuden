import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _urlController = TextEditingController();
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Error: User not logged in for settings.');
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data()!.containsKey('calendarUrl')) {
        final url = userDoc.data()!['calendarUrl'] as String? ?? '';
        setState(() {
          _currentUrl = url;
          _urlController.text = url;
        });
      }
    } catch (e) {
      print('Error fetching calendar URL from Firestore: $e');
    }
  }

  Future<void> _saveUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ログインが必要です',
              style: TextStyle(fontFamily: 'misaki', color: Colors.white),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      }
      return;
    }

    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'calendarUrl': url,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'カレンダーURLを保存しました！',
                style: TextStyle(fontFamily: 'misaki', color: Colors.white),
              ),
              backgroundColor: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white, width: 2.5),
              ),
            ),
          );
          setState(() {
            _currentUrl = url;
          });
        }
      } catch (e) {
        print('Error saving calendar URL to Firestore: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '保存に失敗しました',
                style: TextStyle(fontFamily: 'misaki', color: Colors.white),
              ),
              backgroundColor: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white, width: 2.5),
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'URLを入力してください',
              style: TextStyle(fontFamily: 'misaki', color: Colors.white),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('アカウントの削除'),
            content: const Text(
              '本当によろしいですか？この操作は元に戻せません。すべてのアカウントデータが完全に削除されます。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the confirmation dialog
                  _promptForPassword();
                },
                child: Text('削除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _promptForPassword() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('本人確認'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('アカウントを削除するには、パスワードを再度入力してください。'),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'パスワード'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteAccount(passwordController.text);
                },
                child: const Text('確認'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAccount(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ログインしていません。')));
      return;
    }

    try {
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      // If re-authentication is successful, delete user data and account
      // 1. Delete Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // 2. Delete the user account
      await user.delete();

      // Navigate to login page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('アカウントが削除されました。')));
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'wrong-password') {
        message = 'パスワードが正しくありません。';
      } else if (e.code == 'requires-recent-login') {
        message = 'セキュリティのため、再ログインが必要です。';
      } else {
        message = 'エラーが発生しました: ${e.message}';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('予期せぬエラーが発生しました。')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'misaki',
          ),
        ),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[800]!, Colors.indigo[600]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // KOANのスケジュール設定セクション
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'カレンダー連携',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Image.asset(
                              'assets/calendar.png',
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '大学の授業カレンダーを同期',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'iCal形式(.ics)のURLを貼り付けると、時間割が自動でアプリに反映されます。',
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'カレンダーURL',
                            hintText: 'https://koan.osaka-u.ac.jp/...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _saveUrl,
                            icon: const Icon(Icons.sync),
                            label: const Text('URLを保存・同期'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ExpansionTile(
                          title: Text(
                            'URLの取得方法は？',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '1. 大学のシステム（KOAN等）にログイン\n'
                                '2. スケジュール/時間割画面を開く\n'
                                '3. 「カレンダー」または「iCal」タブをクリック\n'
                                '4. 「iCal」ボタンをクリック\n'
                                '5. 表示されたURLをコピー',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // その他の設定項目をここに追加
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.indigo[800]),
                            const SizedBox(width: 8),
                            Text(
                              'アプリについて',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '履修伝説 v1.1.0\n'
                          '大阪大学の学生生活を楽しくするためのアプリです。',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[800]),
                            const SizedBox(width: 8),
                            Text(
                              'アカウント削除',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'この操作は元に戻せません。アカウントを削除すると、すべてのデータが完全に失われます。',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showDeleteAccountDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('アカウントを削除する'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
