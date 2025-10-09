import "package:flutter/material.dart";
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_page.dart';
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
import 'character_question_page.dart';
import 'user_profile_page.dart';

import 'services/notification_service.dart';
import 'providers/background_image_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'course_registration_page.dart';
import 'widgets/ad_banner.dart';

class MainPage extends ConsumerStatefulWidget {
  final bool showLoginBonus;
  final String universityType;

  const MainPage({
    super.key,
    this.showLoginBonus = false,
    this.universityType = 'main',
  });

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasShownLoginBonus = false;

  // ブランドカラー（ToDoページと揃える）
  static const Color _cPrimary = Color(0xff2e6db6);
  static const Color _cAccent = Color(0xff62b5e5);
  static const Color _cMint = Color(0xff58c3a9);
  static const Color _cWhite = Color(0xFFFFFFFF);
  static const Color _cBlack = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    // FCMトークンを再取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().refreshFCMToken();
    });
  }

  // ToDo風のカードタイル
  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: _cWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
        ),
        child: ListTile(
          leading: Icon(icon, color: _cPrimary),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: 16,
              color: _cBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.black.withOpacity(0.3),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
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

  void _showOtherUnivInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('他大学版について'),
            content: const Text(
              'このアプリは他大学の学生向けに開発中のバージョンです。\n\n'
              '現在は基本的な時間割機能のみ利用可能です。\n'
              '今後、クエスト機能やレビュー機能なども追加予定です。',
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

  void _showDevelopmentStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('開発状況'),
            content: const Text(
              '【実装済み】\n'
              '• 時間割表示・編集\n'
              '• 授業の追加・削除\n'
              '• 基本的なUI\n\n'
              '【開発中】\n'
              '• クエスト機能\n'
              '• レビュー機能\n'
              '• ランキング機能\n\n'
              '【予定】\n'
              '• 他大学向けカスタマイズ\n'
              '• 追加機能',
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

    // 各ページ
    final List<Widget> pages = [
      const RankingPage(),
      const CreditExplorePage(),
      ParkPage(
        diagnosedCharacterName: '剣士',
        answers: const [],
        userName: userName,
        universityType: widget.universityType,
      ),
      TimeSchedulePage(universityType: widget.universityType),
      const ItemPage(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: currentPage.index != 3,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 背景画像
          Positioned.fill(
            child: Image.asset(
              ref.watch(backgroundImagePathProvider),
              fit: BoxFit.cover,
            ),
          ),
          // ページ本体
          Positioned.fill(child: pages[currentPage.index]),

          // メニューボタン（右上） - 時間割ページ（index==3）では非表示
          if (currentPage.index != 3)
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 4),
          Center(
            child: AdBanner(
              testUnitId: 'ca-app-pub-7200045710813069/7211289802',
            ),
          ),
          SizedBox(height: 4),
          CommonBottomNavigation(),
        ],
      ),

      // 冒険のメニュー（白背景）
      endDrawer: Drawer(
        child: Container(
          color: _cWhite,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ヘッダー（半透明ブラー＋ブランドバー）
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: _cPrimary.withOpacity(0.85),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book, color: _cWhite, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            widget.universityType == 'other'
                                ? '他大学メニュー'
                                : '冒険のメニュー',
                            style: const TextStyle(
                              fontFamily: 'NotoSansJP',
                              color: _cWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    _cPrimary,
                                    _cAccent,
                                    _cMint,
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // 大阪大学専用のメニュー項目
                      if (widget.universityType != 'other') ...[
                        _buildDrawerTile(Icons.school_outlined, 'KOAN', () {
                          _launchURL(
                            'https://koan.osaka-u.ac.jp/campusweb/campusportal.do?page=main',
                          );
                        }),
                        _buildDrawerTile(Icons.book_outlined, 'CLE', () {
                          _launchURL(
                            'https://www.cle.osaka-u.ac.jp/ultra/course',
                          );
                        }),
                        _buildDrawerTile(Icons.person_outline, 'マイハンダイ', () {
                          _launchURL('https://my.osaka-u.ac.jp/');
                        }),
                        _buildDrawerTile(Icons.mail_outline, 'OU-Mail', () {
                          _launchURL('https://outlook.office.com/mail/');
                        }),
                        const SizedBox(height: 8),
                      ],

                      // 他大学用のメニュー項目
                      if (widget.universityType == 'other') ...[
                        _buildDrawerTile(Icons.info_outline, '他大学版について', () {
                          Navigator.pop(context);
                          _showOtherUnivInfoDialog(context);
                        }),
                        _buildDrawerTile(Icons.bug_report, '開発状況', () {
                          Navigator.pop(context);
                          _showDevelopmentStatusDialog(context);
                        }),
                        _buildDrawerTile(Icons.school, '講義登録', () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const CourseRegistrationPage(),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],

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
                      const SizedBox(height: 8),

                      _buildDrawerTile(Icons.settings, '設定', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => SettingPage(
                                  universityType: widget.universityType,
                                ),
                          ),
                        );
                      }),
                      _buildDrawerTile(Icons.image, '背景画像を変更', () async {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.refresh,
                                      color: _cAccent,
                                    ),
                                    title: const Text('デフォルト背景に戻す'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await ref
                                          .read(
                                            backgroundImagePathProvider
                                                .notifier,
                                          )
                                          .resetBackgroundImage();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.photo_album,
                                      color: _cAccent,
                                    ),
                                    title: const Text('アルバムから選ぶ'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final picker = ImagePicker();
                                      final picked = await picker.pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      if (picked != null) {
                                        final appDir =
                                            await getApplicationDocumentsDirectory();
                                        final fileName =
                                            'background_${DateTime.now().millisecondsSinceEpoch}${picked.name.substring(picked.name.lastIndexOf('.'))}';
                                        final saved = await File(
                                          picked.path,
                                        ).copy('${appDir.path}/$fileName');
                                        await ref
                                            .read(
                                              backgroundImagePathProvider
                                                  .notifier,
                                            )
                                            .setBackgroundImagePath(saved.path);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const WelcomePage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData) {
              return const WelcomePage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

            // デバッグ用ログ
            print('=== AuthWrapper Debug ===');
            print('User ID: ${snapshot.data!.uid}');
            print('User data exists: ${userData != null}');
            if (userData != null) {
              print('User data keys: ${userData.keys.toList()}');
              print('Character: ${userData['character']}');
              print('Name: ${userData['name']}');
              print('Profile completed: ${userData['profileCompleted']}');
            }

            // ユーザーデータが存在しない場合は診断画面へ
            if (userData == null) {
              print('Redirecting to CharacterQuestionPage - no user data');
              return CharacterQuestionPage();
            }

            // キャラクターが設定されていない場合は診断画面へ
            if (!userData.containsKey('character') ||
                userData['character'] == null) {
              print('Redirecting to CharacterQuestionPage - character not set');
              return CharacterQuestionPage();
            }

            // 名前が設定されていない場合はプロフィール設定画面へ
            if (!userData.containsKey('name') || userData['name'] == null) {
              print('Redirecting to UserProfilePage - name not set');
              return const UserProfilePage();
            }

            print('Redirecting to MainPage - all conditions met');
            return MainPage();
          },
        );
      },
    );
  }
}
