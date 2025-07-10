import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarSettingCard extends StatefulWidget {
  final String universityType;
  const CalendarSettingCard({super.key, this.universityType = 'main'});

  @override
  State<CalendarSettingCard> createState() => _CalendarSettingCardState();
}

class _CalendarSettingCardState extends State<CalendarSettingCard> {
  final TextEditingController _urlController = TextEditingController();
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data.containsKey('calendarUrl')) {
          final url = data['calendarUrl'] as String? ?? '';
          setState(() {
            _currentUrl = url;
            _urlController.text = url;
          });
        }
      }
    } catch (e) {
      print('Error fetching URLs from Firestore: $e');
    }
  }

  Future<void> _saveUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ログインが必要です',
              style: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      }
      return;
    }

    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'calendarUrl': url,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'カレンダーURLを保存しました！\n新規発行のURLは反映まで最大1日程度かかる場合があります。',
                style: TextStyle(
                  fontFamily: 'Noto Sans JP',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white, width: 2.5),
              ),
              duration: Duration(seconds: 5),
            ),
          );
          setState(() {
            _currentUrl = url;
          });
        }
      } catch (e) {
        print('Error saving calendar URL to Firestore: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '保存に失敗しました',
                style: TextStyle(
                  fontFamily: 'Noto Sans JP',
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white, width: 2.5),
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'URLを入力してください',
              style: TextStyle(fontFamily: 'Noto Sans JP', color: Colors.white),
            ),
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white, width: 2.5),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openKoan() async {
    if (widget.universityType == 'other') {
      // 他大学の場合は汎用的なメッセージを表示
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('大学システムについて'),
                content: const Text(
                  'お使いの大学のポータルサイトや学習管理システムにアクセスして、'
                  'カレンダー連携機能からiCal形式(.ics)のURLを取得してください。\n\n'
                  '一般的な手順：\n'
                  '1. 大学のポータルサイトにログイン\n'
                  '2. 授業スケジュールやカレンダー機能を探す\n'
                  '3. カレンダー連携やiCalエクスポート機能を利用\n'
                  '4. 表示されたURLをコピー',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } else {
      // 大阪大学の場合はKOANを開く
      const String koanUrl =
          'https://koan.osaka-u.ac.jp/campusweb/campusportal.do?page=main';
      final Uri url = Uri.parse(koanUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カレンダー連携',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Image.asset(
                  'assets/calender.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.universityType == 'other'
                      ? 'お使いの大学のポータルサイトや学習管理システムから取得したiCal形式(.ics)のURLを下の入力欄に貼り付けてください。\n例: https://your-university.edu/...\n\n※ 新規発行のカレンダーURLは反映まで最大1日程度かかる場合があります。'
                      : 'KOANの休講・スケジュールを選び、カレンダー連携を選択し、URLを作成を押した後、コピーして、下の入力欄に貼り付けてください。\n例: https://koan.osaka-u.ac.jp/...\n\n※ 新規発行のカレンダーURLは反映まで最大1日程度かかる場合があります。',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '大学の授業カレンダーを同期',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'iCal形式(.ics)のURLを貼り付けると、時間割が自動でアプリに反映されます。',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'カレンダーURL',
                hintText:
                    widget.universityType == 'other'
                        ? 'https://your-university.edu/...'
                        : 'https://koan.osaka-u.ac.jp/...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveUrl,
                icon: const Icon(Icons.sync),
                label: const Text('URLを保存・同期'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _openKoan,
                  icon: const Icon(Icons.open_in_new, size: 20),
                  label: Text(
                    widget.universityType == 'other' ? '大学システムについて' : 'KOANを開く',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              title: Text(
                'URLの取得方法は？',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.universityType == 'other'
                        ? '1. お使いの大学のポータルサイトにログイン\n'
                            '2. 授業スケジュールやカレンダー機能を探す\n'
                            '3. カレンダー連携やiCalエクスポート機能を利用\n'
                            '4. URLを作成またはエクスポートを押す\n'
                            '5. 表示されたURLをコピー'
                        : '1. 大学のシステム（KOAN等）にログイン\n'
                            '2. 休講・スケジュールを押す\n'
                            '3. カレンダー連携を押す\n'
                            '4. URLを作成を押す\n'
                            '5. 表示されたURLをコピー',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
