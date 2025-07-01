import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'character_question_page.dart';
import 'user_profile_page.dart';
import 'main_page.dart';

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
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null || !userData.containsKey('character')) {
              return CharacterQuestionPage();
            }
            if (!userData.containsKey('profileCompleted') ||
                userData['profileCompleted'] != true) {
              return const UserProfilePage();
            }
            return MainPage();
          },
        );
      },
    );
  }
}
