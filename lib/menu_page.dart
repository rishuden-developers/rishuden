import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'mail_page.dart';
import 'setting_page/setting_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/background_image_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'player_log_page.dart';
import 'dart:io';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu Page')),
      body: Center(
        child: Column(
          children: [
            Text('ここが遷移先のページです！'),
            ElevatedButton(
              child: Text('お問合せ'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MailPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('プレイヤー記録'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlayerLogPage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('設定'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage()),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansJP',
                ),
              ),
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  final appDir = await getApplicationDocumentsDirectory();
                  final fileName =
                      'background_${DateTime.now().millisecondsSinceEpoch}${picked.name.substring(picked.name.lastIndexOf('.'))}';
                  final saved = await File(
                    picked.path,
                  ).copy('${appDir.path}/$fileName');
                  await ref
                      .read(backgroundImagePathProvider.notifier)
                      .setBackgroundImagePath(saved.path);
                }
              },
              child: const Text('背景画像を変更'),
            ),
          ],
        ),
      ),
    );
  }
}
