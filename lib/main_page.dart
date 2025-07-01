import "package:flutter/material.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'mail_page.dart';
import 'park_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'common_bottom_navigation.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'providers/current_page_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'credit_explore_page.dart';
import 'setting_page/setting_page.dart';
import 'menu_page.dart';

class MainPage extends ConsumerStatefulWidget {
  final bool showLoginBonus;

  const MainPage({super.key, this.showLoginBonus = false});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasShownLoginBonus = false;

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
  Widget build(BuildContext context) {
    // ログインボーナス通知を表示（一度だけ）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showLoginBonus && !_hasShownLoginBonus) {
        setState(() {
          _hasShownLoginBonus = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインボーナス！ たこ焼きを 1個 獲得しました！'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

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
      endDrawer: MenuPageDrawer()
    );
  }
}