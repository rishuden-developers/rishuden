// credit_result_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'credit_review_page.dart'; // レビュー詳細ページへの遷移用
import 'common_bottom_navigation.dart'; // 共通フッターウィジェット
import 'park_page.dart';
import 'time_schedule_page.dart';
import 'ranking_page.dart';
import 'item_page.dart';
import 'credit_explore_page.dart'; // ボトムナビゲーション用
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ★レート表示に利用するパッケージをインポート
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rishuden/providers/global_course_mapping_provider.dart';
import 'package:rishuden/providers/global_review_mapping_provider.dart';

// 検索結果の各講義を表すデータモデル
class LectureSearchResult {
  final String lectureName;
  final String teacherName;
  final String? reviewId;
  double avgSatisfaction;
  double avgEasiness;
  int reviewCount;

  LectureSearchResult({
    required this.lectureName,
    required this.teacherName,
    this.reviewId,
    this.avgSatisfaction = 0.0,
    this.avgEasiness = 0.0,
    this.reviewCount = 0,
  });
}

class CreditResultPage extends ConsumerStatefulWidget {
  final String? searchQuery; // 検索クエリがあれば受け取る
  final String? filterFaculty; // 学部フィルター
  final String? filterTag; // タグフィルター
  final String? filterCategory; // 種類フィルター (必修/選択)
  final String? filterDayOfWeek; // 曜日フィルター
  final String?
  rankingType; // ランキングの種類 ('easiness', 'satisfaction', 'faculty_specific')

  const CreditResultPage({
    super.key,
    this.searchQuery,
    this.filterFaculty,
    this.filterTag,
    this.filterCategory,
    this.filterDayOfWeek,
    this.rankingType,
  });

  @override
  ConsumerState<CreditResultPage> createState() => _CreditResultPageState();
}

class _CreditResultPageState extends ConsumerState<CreditResultPage> {
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
  }

  String _getPageTitle() {
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return '検索結果: "${widget.searchQuery}"';
    } else if (widget.rankingType == 'easiness') {
      return '楽単ランキング';
    } else if (widget.rankingType == 'satisfaction') {
      return '総合満足度ランキング';
    } else if (widget.rankingType == 'faculty_specific') {
      return '${widget.filterFaculty ?? '全学部'} 注目授業';
    } else if (widget.filterFaculty != null &&
        widget.filterFaculty!.isNotEmpty) {
      return '${widget.filterFaculty} の講義';
    }
    return '講義一覧';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansJP',
          ),
        ),
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[800]!, Colors.indigo[600]!],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('master_courses')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'エラーが発生しました',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  '講義データがありません',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            // カテゴリ一覧を抽出
            final allCategoriesRaw =
                snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  return data != null && data.containsKey('category')
                      ? data['category'] as String? ?? ''
                      : '';
                }).toList();
            final categorySet = allCategoriesRaw.toSet();
            final categories =
                categorySet.where((c) => c.isNotEmpty).toList()..sort();
            if (allCategoriesRaw.any((c) => c.isEmpty)) {
              categories.insert(0, '未分類');
            }
            _categories = categories;

            // 絞り込み
            var filteredDocs = snapshot.data!.docs;
            if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
              if (_selectedCategory == '未分類') {
                filteredDocs =
                    filteredDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      return data == null ||
                          !data.containsKey('category') ||
                          (data['category'] ?? '') == '';
                    }).toList();
              } else {
                filteredDocs =
                    filteredDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      return data != null &&
                          data.containsKey('category') &&
                          data['category'] == _selectedCategory;
                    }).toList();
              }
            }
            if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
              filteredDocs =
                  filteredDocs.where((doc) {
                    final name = (doc['name'] ?? '').toString().toLowerCase();
                    final teacher =
                        (doc['instructor'] ?? '').toString().toLowerCase();
                    return name.contains(widget.searchQuery!.toLowerCase()) ||
                        teacher.contains(widget.searchQuery!.toLowerCase());
                  }).toList();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: const Text('教科で絞り込む'),
                    items:
                        _categories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CreditReviewPage(
                                      lectureName: doc['name'] ?? '',
                                      teacherName: doc['instructor'] ?? '',
                                    ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansJP',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doc['instructor'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontFamily: 'NotoSansJP',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '教科: ${(doc.data() as Map<String, dynamic>?) != null && (doc.data() as Map<String, dynamic>).containsKey('category') ? (doc['category'] ?? '未分類') : '未分類'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '曜日: ${((doc.data() as Map<String, dynamic>?)?['day'] ?? '')}  時限: ${((doc.data() as Map<String, dynamic>?)?['period'] ?? '')}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
