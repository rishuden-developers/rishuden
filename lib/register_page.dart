import 'package:flutter/material.dart';
import 'character_question_page.dart'; // 👈 これを追加！

class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登録ページ')),
      body: Center(
        child: ElevatedButton(
          child: Text('キャラ診断へ'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterQuestionPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}

