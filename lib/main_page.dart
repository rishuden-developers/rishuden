import "package:flutter/material.dart";
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'mail_page.dart';
import 'news_page.dart';
import 'park_page.dart';
import 'character_question_page.dart';
import 'user_profile_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'common_bottom_navigation.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'credit_review_page.dart';
import 'providers/current_page_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'credit_explore_page.dart';
import 'setting_page.dart';

class MainPage extends ConsumerWidget {
  MainPage({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // park_page.dart から Drawer内のタイルを作成するメソッドを移植
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

  // park_page.dart から URLを起動するメソッドを移植
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  // park_page.dart から お知らせダイアログを表示するメソッドを移植 (内容は一部簡略化)
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
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'ゲスト';

    final pageTitles = ['ランキング', '単位検索', 'クエスト', '時間割', 'アイテム'];
    final pageTitle = pageTitles[currentPage.index];

    // 各ページのウィジェットをリストとして定義
    final List<Widget> pages = [
      const RankingPage(),
      const CreditExplorePage(),
      ParkPage(
        diagnosedCharacterName: '剣士',
        answers: const [],
        userName: userName,
      ),
      const TimeSchedulePage(),
      const ItemPage(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          IndexedStack(index: currentPage.index, children: pages),
          if (currentPage == AppPage.park)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              right: 5,
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 32,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4.0,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigation(),
      // park_page.dart から Drawer のコードを移植
      endDrawer: Drawer(
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
                    bottom: BorderSide(color: Colors.amber[300]!, width: 2),
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
              }),
              _buildDrawerTile(Icons.report_problem_outlined, 'ユーザー通報', () {
                Navigator.pop(context);
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

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

            // キャラクターが選択されていない場合
            if (userData == null || !userData.containsKey('character')) {
              return CharacterQuestionPage();
            }

            // プロフィールが未完了の場合
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
