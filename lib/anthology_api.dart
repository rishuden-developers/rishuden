import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

Future<void> fetchAccessToken() async {
  // ① Blackboard Learnのドメイン
  const learnHost = 'www.cle.osaka-u.ac.jp';

  // ② あなたのApp IDとSecret
  const clientId = 'e054adc2-f587-4a3a-bd1d-8781bc8d78ed';
  const clientSecret = 'zeJIJZBMM2XRMH8YPamCXz8p4OSqYSfL';

  // ③ Basic認証ヘッダー用エンコード
  final basicAuth = base64Encode(utf8.encode('$clientId:$clientSecret'));

  final url = Uri.https(learnHost, '/learn/api/public/v1/oauth2/token');

  final headers = {
    'Authorization': 'Basic $basicAuth',
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  final body = 'grant_type=client_credentials';

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    final accessToken = json['access_token'];
    print('🎉 Access Token: $accessToken');
  } else {
    print('❌ Token取得失敗: ${response.statusCode}');
    print(response.body);
  }
}

class ApiApp extends StatelessWidget {
  const ApiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blackboard Learn API App',
      home: Scaffold(
        appBar: AppBar(title: Text('Blackboard Learn API App')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await fetchAccessToken();
            },
            child: Text('Fetch Access Token'),
          ),
        ),
      ),
    );
  }
}
