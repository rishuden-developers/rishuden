import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_page.dart';
import 'character_question_page.dart';

class UserDataChecker extends StatelessWidget {
  const UserDataChecker({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // これは基本的には起こらないはず
      return const Scaffold(body: Center(child: Text('エラー: ユーザーがいません')));
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
            // キャラクター設定済み
            return MainPage();
          }
        }

        // ドキュメントがない、またはキャラクターが未設定
        return CharacterQuestionPage();
      },
    );
  }
}
