import 'package:flutter/material.dart';
import 'character_question_page.dart';

class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Page')),
      body: Center(
        child: ElevatedButton(
          child: Text('新規登録'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CharacterQuestionPage()),
            );
          },
        ),
      ),
    );
  }
}
