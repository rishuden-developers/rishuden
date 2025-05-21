import 'package:flutter/material.dart';
import 'character_decide_page.dart';

class CharacterQuestionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Page')),
      body: Center(
        child: ElevatedButton(
          child: Text('キャラ診断'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CharacterDecidePage()),
            );
          },
        ),
      ),
    );
  }
}
