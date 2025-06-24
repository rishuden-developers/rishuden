import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class DataUploadPage extends StatefulWidget {
  const DataUploadPage({super.key});

  @override
  State<DataUploadPage> createState() => _DataUploadPageState();
}

class _DataUploadPageState extends State<DataUploadPage> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isUploading = false;
  String _uploadStatus = '';
  String? _lastUploadedDocId;

  Future<void> _uploadJson() async {
    setState(() {
      _isUploading = true;
      _uploadStatus = '';
      _lastUploadedDocId = null;
    });
    try {
      final jsonString = _jsonController.text.trim();
      if (jsonString.isEmpty) {
        setState(() {
          _uploadStatus = 'JSONを入力してください。';
          _isUploading = false;
        });
        return;
      }
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      // Firestoreにアップロード
      final docRef = await FirebaseFirestore.instance
          .collection('course_data')
          .add({'uploadedAt': FieldValue.serverTimestamp(), 'data': jsonData});
      setState(() {
        _isUploading = false;
        _uploadStatus = 'アップロード完了 (ID: ${docRef.id})';
        _lastUploadedDocId = docRef.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アップロードが完了しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'エラー: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アップロードエラー: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'コースデータアップロード',
          style: TextStyle(fontFamily: 'misaki', color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background_plaza.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: const [
                      Text(
                        'コースデータアップロード',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'misaki',
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '下のテキストエリアにJSONデータをコピペしてアップロードできます。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _jsonController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'ここにJSONデータを貼り付けてください...',
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadJson,
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  'アップロード',
                  style: TextStyle(fontFamily: 'misaki'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              if (_isUploading)
                const Center(child: CircularProgressIndicator()),
              if (_uploadStatus.isNotEmpty)
                Card(
                  color:
                      _uploadStatus.startsWith('エラー')
                          ? Colors.red[100]
                          : Colors.green[100],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _uploadStatus,
                      style: TextStyle(
                        color:
                            _uploadStatus.startsWith('エラー')
                                ? Colors.red
                                : Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
