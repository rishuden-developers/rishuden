import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/app_theme.dart';

/// 既存のParkPageのデータ取得・イベントを流用して
/// シンプルなMaterial 3準拠の課題一覧UIを表示する画面。
class HomeSimpleScreen extends ConsumerStatefulWidget {
  final String userName;
  final VoidCallback onTapOztechLogo; // 右上ロゴ: 既存のダイアログ/遷移を呼ぶ
  final VoidCallback onTapMapIcon; // 右上マップアイコン: 既存の挙動を呼ぶ
  final Future<void> Function() onAddOrCheckQuest; // CTA: 既存onPressed

  const HomeSimpleScreen({
    super.key,
    required this.userName,
    required this.onTapOztechLogo,
    required this.onTapMapIcon,
    required this.onAddOrCheckQuest,
  });

  @override
  ConsumerState<HomeSimpleScreen> createState() => _HomeSimpleScreenState();
}

class _HomeSimpleScreenState extends ConsumerState<HomeSimpleScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _quests = [];

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _quests = [];
          _loading = false;
        });
        return;
      }

      // ユーザーが履修しているcourseIdの集合を取得
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('timetable')
              .doc('notes')
              .get();

      final userCourseIds =
          userDoc.exists
              ? Map<String, String>.from(userDoc.data()!['courseIds'] ?? {})
              : <String, String>{};

      if (userCourseIds.isEmpty) {
        setState(() {
          _quests = [];
          _loading = false;
        });
        return;
      }

      final ids = userCourseIds.values.toSet().toList();
      final snap =
          await FirebaseFirestore.instance
              .collection('quests')
              .where('courseId', whereIn: ids)
              .get();

      final me = user.uid;
      final items =
          snap.docs.map((d) => {'id': d.id, ...d.data()}).where((q) {
              final completed =
                  (q['completedUserIds'] as List?)?.cast<String>() ?? [];
              return !completed.contains(me);
            }).toList()
            ..sort((a, b) {
              final ad = a['deadline'] as Timestamp?;
              final bd = b['deadline'] as Timestamp?;
              if (ad == null && bd == null) return 0;
              if (ad == null) return 1;
              if (bd == null) return -1;
              return ad.compareTo(bd);
            });

      setState(() {
        _quests = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  bool _isExpired(Timestamp? ts) {
    if (ts == null) return false;
    return ts.toDate().isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // OZTECHロゴ（既存の挙動を上位から受け取り、そのまま呼ぶ）
          IconButton(
            onPressed: widget.onTapOztechLogo,
            icon: Image.asset('assets/oztech.png', width: 28, height: 28),
            tooltip: 'OZTECH',
          ),
          // マップアイコン（既存挙動維持）
          IconButton(
            onPressed: widget.onTapMapIcon,
            icon: const Icon(Icons.map_outlined, color: AppTheme.black),
            tooltip: 'Map',
          ),
        ],
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              )
              : _quests.isEmpty
              ? const Center(
                child: Text(
                  '現在、討伐対象のクエストはありません。',
                  style: TextStyle(color: AppTheme.black),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _quests.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final q = _quests[index];
                  final String title = (q['name'] ?? '') as String;
                  final Timestamp? deadline = q['deadline'] as Timestamp?;
                  final bool expired = _isExpired(deadline);
                  final String deadlineText =
                      deadline == null
                          ? '期限未設定'
                          : _formatDeadline(deadline.toDate());

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        expired
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: expired ? Colors.red : AppTheme.black,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(color: AppTheme.black),
                      ),
                      subtitle: Text(
                        deadlineText,
                        style: TextStyle(
                          color: expired ? Colors.red : AppTheme.black,
                        ),
                      ),
                      onTap: () {
                        // 既存の詳細や提出処理がある場合は、ここから既存遷移を呼ぶよう拡張可能
                      },
                    ),
                  );
                },
              ),
      bottomNavigationBar: const SizedBox(
        height: 0, // 実際のボトムナビはMainPage側で配置されるためここは空にしておく
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              await widget.onAddOrCheckQuest();
              if (mounted) _loadQuests();
            },
            child: const Text('クエストを追加/確認'),
          ),
        ),
      ),
    );
  }

  String _formatDeadline(DateTime dt) {
    // yyyy/MM/dd HH:mm の簡易表示
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)} まで';
  }
}
