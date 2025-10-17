import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'character_question_page.dart';
import 'main_page.dart';
import 'user_profile_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const LoginPage();
        }
  return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!userSnapshot.hasData) {
              return const LoginPage();
            }
            final doc = userSnapshot.data!;
            // ユーザードキュメントが存在しない場合は診断へ（初回作成時に users/{uid} を作る）
            if (!doc.exists) {
              return CharacterQuestionPage();
            }
            final userData = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
            // タイプ診断（character）が未完了なら診断へ（null や 空文字も未完了扱い）
            final dynamic charField = userData['character'];
            final bool hasCharacter = charField is String && charField.trim().isNotEmpty;
            if (!hasCharacter) {
              return CharacterQuestionPage();
            }

            // プロフィール未完了ならプロフィール設定へ
            final bool isNameMissing =
                !userData.containsKey('name') ||
                userData['name'] == null ||
                (userData['name'] is String && (userData['name'] as String).trim().isEmpty);
            final bool isGradeMissing = !userData.containsKey('grade') || userData['grade'] == null;
            final bool isDepartmentMissing = !userData.containsKey('department') || userData['department'] == null;
            final bool profileCompletedFlag = userData['profileCompleted'] == true;
            if (isNameMissing || isGradeMissing || isDepartmentMissing || !profileCompletedFlag) {
              return const UserProfilePage();
            }
            // 大学タイプを取得（main or other）
            final universityType = userData['universityType'] ?? 'main';
            // MainPageに渡す（今後Provider化も検討）
            return MainPage(universityType: universityType);
          },
        );
      },
    );
  }
}
