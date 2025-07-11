import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../welcome_page.dart';

class DeleteAccountCard extends StatefulWidget {
  const DeleteAccountCard({super.key});

  @override
  State<DeleteAccountCard> createState() => _DeleteAccountCardState();
}

class _DeleteAccountCardState extends State<DeleteAccountCard> {
  bool _isDeleting = false;

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

    setState(() {
      _isDeleting = true;
    });

    try {
      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      // If re-authentication is successful, delete user data and account

      try {
        // 1. ユーザーが作成したクエストを削除
        final questsSnapshot =
            await FirebaseFirestore.instance
                .collection('quests')
                .where('createdBy', isEqualTo: user.uid)
                .get();

        for (var doc in questsSnapshot.docs) {
          await doc.reference.delete();
        }

        // 2. ユーザーの通知データを削除
        final notificationsSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .get();

        for (var doc in notificationsSnapshot.docs) {
          await doc.reference.delete();
        }

        // 3. ユーザーの時間割データを削除
        final timetableSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('timetable')
                .get();

        for (var doc in timetableSnapshot.docs) {
          await doc.reference.delete();
        }

        // 4. ユーザーが参加したクエストからcompletedUserIdsとsupporterIdsを削除
        final allQuestsSnapshot =
            await FirebaseFirestore.instance.collection('quests').get();

        for (var doc in allQuestsSnapshot.docs) {
          final questData = doc.data();
          final completedUserIds = List<String>.from(
            questData['completedUserIds'] ?? [],
          );
          final supporterIds = List<String>.from(
            questData['supporterIds'] ?? [],
          );

          if (completedUserIds.contains(user.uid) ||
              supporterIds.contains(user.uid)) {
            await doc.reference.update({
              'completedUserIds': FieldValue.arrayRemove([user.uid]),
              'supporterIds': FieldValue.arrayRemove([user.uid]),
            });
          }
        }

        // 5. ユーザーのメインドキュメントを削除（レビューデータは残す）
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // 6. Firebase Authのアカウントを削除
        await user.delete();
      } catch (e) {
        print('Error during account deletion: $e');
        // データ削除中にエラーが発生した場合でも、アカウント削除は試行
        await user.delete();
      }

      // Navigate to login page
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
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
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('予期せぬエラーが発生しました。')));
      }
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
              onPressed: _isDeleting ? null : _showDeleteAccountDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child:
                  _isDeleting
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('削除中...'),
                        ],
                      )
                      : const Text('アカウントを削除する'),
            ),
          ],
        ),
      ),
    );
  }
}
