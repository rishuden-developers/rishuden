import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class JsonPasteUploadPage extends StatefulWidget {
  @override
  _JsonPasteUploadPageState createState() => _JsonPasteUploadPageState();
}

class _JsonPasteUploadPageState extends State<JsonPasteUploadPage> {
  final TextEditingController _controller = TextEditingController();
  String? _message;

  Future<void> uploadJson() async {
    try {
      final jsonData = json.decode(_controller.text);
      // 例: Firestoreの "courses" コレクションに追加
      await FirebaseFirestore.instance.collection('courses').add(jsonData);
      setState(() {
        _message = "アップロード成功！";
      });
    } catch (e) {
      setState(() {
        _message = "エラー: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('JSONコピペアップロード')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('ここにJSONを貼り付けてください:'),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'ここにJSONをコピペ',
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: uploadJson, child: Text('アップロード')),
            if (_message != null) ...[SizedBox(height: 16), Text(_message!)],
          ],
        ),
      ),
    );
  }
}
