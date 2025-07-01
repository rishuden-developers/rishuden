import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'mail_page.dart';
import 'setting_page/setting_page.dart';

class MenuPageDrawer extends StatelessWidget {
  const MenuPageDrawer({super.key});

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber[200]),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'misaki',
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.amber.withOpacity(0.1),
    );
  }

  void _showNoticeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('お知らせ'),
            content: const Text('新しいお知らせはありません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ranking_guild_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.amber, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.menu_book, color: Colors.white, size: 36),
                  SizedBox(height: 10),
                  Text(
                    '冒険のメニュー',
                    style: TextStyle(
                      fontFamily: 'misaki',
                      color: Colors.white,
                      fontSize: 22,
                      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerTile(Icons.school_outlined, 'KOAN', () {
              _launchURL(
                'https://koan.osaka-u.ac.jp/campusweb/campusportal.do?page=main',
              );
            }),
            _buildDrawerTile(Icons.book_outlined, 'CLE', () {
              _launchURL('https://www.cle.osaka-u.ac.jp/ultra/course');
            }),
            _buildDrawerTile(Icons.person_outline, 'マイハンダイ', () {
              _launchURL('https://my.osaka-u.ac.jp/');
            }),
            _buildDrawerTile(Icons.mail_outline, 'OU-Mail', () {
              _launchURL('https://outlook.office.com/mail/');
            }),
            Divider(color: Colors.amber[200]),
            _buildDrawerTile(Icons.mail, 'お問い合わせ', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MailPage()),
              );
            }),
            _buildDrawerTile(Icons.info_outline, 'お知らせを見る', () {
              Navigator.pop(context);
              _showNoticeDialog(context);
            }),
            Divider(color: Colors.amber[200]),
            _buildDrawerTile(Icons.settings, '設定', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
            }),
            _buildDrawerTile(Icons.help_outline, 'ヘルプ', () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('ヘルプ'),
                      content: const Text('ヘルプ機能は現在準備中です。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
              );
            }),
            _buildDrawerTile(Icons.report_problem_outlined, 'ユーザー通報', () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('ユーザー通報'),
                      content: const Text('ユーザー通報機能は現在準備中です。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
