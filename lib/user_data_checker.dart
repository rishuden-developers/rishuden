import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'character_question_page.dart';
import 'package:intl/intl.dart';
import 'welcome_page.dart';

class UserDataChecker extends StatefulWidget {
  const UserDataChecker({super.key});

  @override
  State<UserDataChecker> createState() => _UserDataCheckerState();
}

class _UserDataCheckerState extends State<UserDataChecker> {
  bool _isCheckingBonus = true;
  bool _bonusGiven = false;

  @override
  void initState() {
    super.initState();
    _checkAndGiveLoginBonus();
  }

  Future<void> _checkAndGiveLoginBonus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastBonusDate = userData['lastLoginBonusDate'] as String?;

      // 今日まだボーナスを受け取っていない場合
      if (lastBonusDate != today) {
        await userRef.update({
          'takoyakiCount': FieldValue.increment(1),
          'lastLoginBonusDate': today,
        });

        setState(() {
          _bonusGiven = true;
        });
      }
    } catch (e) {
      print('Error giving login bonus: $e');
    } finally {
      setState(() {
        _isCheckingBonus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // ユーザーがいない場合はウェルカムページにリダイレクト
      return const WelcomePage();
    }

    // ボーナスチェック中はローディング表示
    if (_isCheckingBonus) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('ログインボーナスをチェック中...'),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('エラー: ${snapshot.error}')));
        }

        // ドキュメントが存在し、'character'フィールドがあるかチェック
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('character') && data['character'] != null) {
            // キャラクター設定済み - ボーナスフラグを渡す
            return MainPage(showLoginBonus: _bonusGiven);
          }
        }

        // ドキュメントがない、またはキャラクターが未設定
        return CharacterQuestionPage();
      },
    );
  }
}
