import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_page.dart';

class DeleteAccountCard extends StatefulWidget {
  const DeleteAccountCard({super.key});

  @override
  State<DeleteAccountCard> createState() => _DeleteAccountCardState();
}

class _DeleteAccountCardState extends State<DeleteAccountCard> {
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
                child: const Text('削除', style: TextStyle(color: Colors.red)),
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
      ).showSnackBar(const SnackBar(content: Text('ログインしていません。')));
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
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('アカウントが削除されました。')));
      }
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
      ).showSnackBar(const SnackBar(content: Text('予期せぬエラーが発生しました。')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
    );
  }
}
