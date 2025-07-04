import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/course_card.dart';
import 'providers/timetable_provider.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart';
import 'providers/current_page_provider.dart';
import 'credit_input_page.dart' show tagOptions;
import 'providers/background_image_provider.dart';

class SpringSummerCourseCardListPage extends ConsumerStatefulWidget {
  const SpringSummerCourseCardListPage({super.key});

  @override
  ConsumerState<SpringSummerCourseCardListPage> createState() =>
      _SpringSummerCourseCardListPageState();
}

class _SpringSummerCourseCardListPageState
    extends ConsumerState<SpringSummerCourseCardListPage> {
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _pagedCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;
  static const int pageSize = 20;
  int _currentPage = 1;
  late PageController _pageController;

  // 検索・フィルター用
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFaculty;
  String? _selectedTag;
  bool _isSearchExpanded = false; // 検索機能の表示/非表示

  final List<String> _faculties = [
    '工学部',
    '理学部',
    '医学部',
    '歯学部',
    '薬学部',
    '文学部',
    '法学部',
    '経済学部',
    '人間科学部',
    '外国語学部',
    '基礎工学部',
  ];
  final List<String> _tags = tagOptions;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSpringSummerCourses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 春夏学期の授業データを読み込む
  Future<void> _loadSpringSummerCourses() async {
    try {
      var courses = <Map<String, dynamic>>[];

      // global/course_mappingドキュメントからmappingフィールドを取得
      final doc =
          await FirebaseFirestore.instance
              .collection('global')
              .doc('course_mapping')
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        final mapping = data['mapping'] as Map<String, dynamic>? ?? {};
        print('mapping runtimeType: \\${mapping.runtimeType}');

        // mappingの各エントリを処理
        for (final entry in mapping.entries) {
          final courseId = entry.key; // 「講義名|教室|曜日|時限」形式
          final courseData = entry.value;

          print(
            'courseData for $courseId: $courseData (type: ${courseData.runtimeType})',
          );

          // courseIdをパースして講義名と教室を取得
          String lectureName = '';
          String classroom = '';

          if (courseId.contains('|')) {
            final parts = courseId.split('|');
            if (parts.length >= 2) {
              lectureName = parts[0];
              classroom = parts[1];
            }
          } else {
            // 古い形式の場合はcourseIdをそのまま講義名として使用
            lectureName = courseId;
          }

          // 教員名をtimetableProviderから取得（時間割画面と同期）
          String teacherName = '';

          // courseDataがMap型の場合のみアクセス
          if (courseData is Map<String, dynamic>) {
            teacherName =
                courseData['teacherName'] ?? courseData['instructor'] ?? '';
          }

          if (courseId.isNotEmpty) {
            final timetableTeacherName =
                ref.read(timetableProvider)['teacherNames']?[courseId];
            if (timetableTeacherName != null &&
                timetableTeacherName.isNotEmpty) {
              teacherName = timetableTeacherName;
            }
          }

          courses.add({
            'courseId': courseId,
            'lectureName': lectureName,
            'classroom': classroom,
            'teacherName': teacherName,
            'avgSatisfaction': 0.0,
            'avgEasiness': 0.0,
            'reviewCount': 0,
            'hasMyReview': false,
          });
        }
      }

      // 各授業のレビュー情報を取得
      for (int i = 0; i < courses.length; i++) {
        final courseId = courses[i]['courseId'];
        try {
          final reviewsSnapshot =
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('courseId', isEqualTo: courseId)
                  .get();

          final reviews = reviewsSnapshot.docs;
          if (reviews.isNotEmpty) {
            double totalSatisfaction = 0.0;
            double totalEasiness = 0.0;
            bool hasMyReview = false;
            final user = FirebaseAuth.instance.currentUser;

            for (final doc in reviews) {
              final data = doc.data();
              final satisfaction =
                  (data['overallSatisfaction'] ?? data['satisfaction'] ?? 0.0) *
                  1.0;
              final easiness = (data['easiness'] ?? data['ease'] ?? 0.0) * 1.0;

              totalSatisfaction += satisfaction;
              totalEasiness += easiness;

              // 自分のレビューがあるかチェック
              if (user != null && data['userId'] == user.uid) {
                hasMyReview = true;
              }
            }

            courses[i] = {
              ...courses[i],
              'avgSatisfaction': totalSatisfaction / reviews.length,
              'avgEasiness': totalEasiness / reviews.length,
              'reviewCount': reviews.length,
              'hasMyReview': hasMyReview,
            };
          }
        } catch (e) {
          print('Error fetching reviews for $courseId: $e');
        }
      }

      print('courses runtimeType before setState: \\${courses.runtimeType}');
      if (courses is Map) {
        print('courses is Map! Converting to List.');
        // 念のためvaluesをtoList
        // ignore: prefer_collection_literals
        courses = List<Map<String, dynamic>>.from((courses as Map).values);
      }

      setState(() {
        _allCourses = courses;
        _filteredCourses = courses;
        _pagedCourses = _getPagedCourses(1);
        _isLoading = false;
      });

      print('Loaded ${courses.length} courses from course_mapping');
    } catch (e) {
      print('Error loading spring/summer courses: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getPagedCourses(int page) {
    final start = (page - 1) * pageSize;
    final end =
        (start + pageSize) > _filteredCourses.length
            ? _filteredCourses.length
            : (start + pageSize);
    return _filteredCourses.sublist(start, end);
  }

  // フィルタリングを適用
  void _applyFilters() async {
    List<Map<String, dynamic>> filtered = _allCourses;

    // 検索クエリでフィルタリング
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered =
          filtered.where((course) {
            final lectureName =
                (course['lectureName'] ?? '').toString().toLowerCase();
            final teacherName =
                (course['teacherName'] ?? '').toString().toLowerCase();
            return lectureName.contains(searchLower) ||
                teacherName.contains(searchLower);
          }).toList();
    }

    // 学部フィルター（その学部の人がレビューを投稿している授業を絞り込み）
    if (_selectedFaculty != null && _selectedFaculty!.isNotEmpty) {
      filtered = await _filterByFaculty(filtered, _selectedFaculty!);
    }

    // タグフィルター（そのタグが使われている授業を絞り込み）
    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      filtered = await _filterByTag(filtered, _selectedTag!);
    }

    setState(() {
      _filteredCourses = filtered;
      _currentPage = 1;
      _pagedCourses = _getPagedCourses(1);
    });
  }

  // 学部フィルター（その学部の人がレビューを投稿している授業を絞り込み）
  Future<List<Map<String, dynamic>>> _filterByFaculty(
    List<Map<String, dynamic>> courses,
    String faculty,
  ) async {
    try {
      // 指定された学部のユーザーを取得
      final usersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('department', isEqualTo: faculty)
              .get();

      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      if (userIds.isEmpty) return [];

      // その学部のユーザーがレビューを投稿している授業のcourseIdを取得
      final reviewsSnapshot =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('userId', whereIn: userIds)
              .get();

      final reviewedCourseIds =
          reviewsSnapshot.docs
              .map((doc) => doc.data()['courseId'] as String?)
              .where((courseId) => courseId != null && courseId.isNotEmpty)
              .toSet();

      // 該当する授業のみを返す
      return courses.where((course) {
        final courseId = course['courseId'] ?? '';
        return reviewedCourseIds.contains(courseId);
      }).toList();
    } catch (e) {
      print('Error filtering by faculty: $e');
      return courses;
    }
  }

  // タグフィルター（そのタグが使われている授業を絞り込み）
  Future<List<Map<String, dynamic>>> _filterByTag(
    List<Map<String, dynamic>> courses,
    String tag,
  ) async {
    try {
      // 指定されたタグが使われているレビューを取得
      final reviewsSnapshot =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('tags', arrayContains: tag)
              .get();

      final reviewedCourseIds =
          reviewsSnapshot.docs
              .map((doc) => doc.data()['courseId'] as String?)
              .where((courseId) => courseId != null && courseId.isNotEmpty)
              .toSet();

      // 該当する授業のみを返す
      return courses.where((course) {
        final courseId = course['courseId'] ?? '';
        return reviewedCourseIds.contains(courseId);
      }).toList();
    } catch (e) {
      print('Error filtering by tag: $e');
      return courses;
    }
  }

  void _nextPage() {
    if (_currentPage * pageSize < _filteredCourses.length) {
      setState(() {
        _currentPage++;
        _pagedCourses = _getPagedCourses(_currentPage);
      });
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _pagedCourses = _getPagedCourses(_currentPage);
      });
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topOffset =
        kToolbarHeight + MediaQuery.of(context).padding.top;
    final int totalPages = (_filteredCourses.length / pageSize).ceil();
    const double bottomNavHeight = 95.0;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            ref.watch(backgroundImagePathProvider),
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
        Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppBar(
                  title: const Text('春夏学期の授業一覧'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                  actions: [
                    // 検索アイコン
                    IconButton(
                      icon: Icon(
                        _isSearchExpanded ? Icons.close : Icons.search,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchExpanded = !_isSearchExpanded;
                          // 検索を閉じる時は検索条件をクリア
                          if (!_isSearchExpanded) {
                            _searchController.clear();
                            _selectedFaculty = null;
                            _selectedTag = null;
                            _applyFilters();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              // ページネーション＋PageView
              Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                bottom: 0,
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : Column(
                          children: [
                            // 検索・フィルターUI（折りたたみ式）
                            if (_isSearchExpanded) ...[
                              _buildSearchAndFilterUI(),
                              const SizedBox(height: 10),
                            ],
                            // ページネーションUI
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      minimumSize: Size(32, 32),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed:
                                        _currentPage > 1 ? _prevPage : null,
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${((_currentPage - 1) * pageSize + 1)}-${((_currentPage - 1) * pageSize + _pagedCourses.length)}件 / 全${_filteredCourses.length}件',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      minimumSize: Size(32, 32),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed:
                                        _currentPage * pageSize <
                                                _filteredCourses.length
                                            ? _nextPage
                                            : null,
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      '',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 横スクロールPageView
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: totalPages,
                                onPageChanged: (pageIdx) {
                                  setState(() {
                                    _currentPage = pageIdx + 1;
                                    _pagedCourses = _getPagedCourses(
                                      _currentPage,
                                    );
                                  });
                                },
                                itemBuilder: (context, pageIdx) {
                                  final paged = _getPagedCourses(pageIdx + 1);
                                  return ListView.builder(
                                    physics: ClampingScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                      bottom: 80,
                                      top: 0,
                                      left: 16,
                                      right: 16,
                                    ),
                                    itemCount: paged.length,
                                    itemBuilder: (context, index) {
                                      final course = paged[index];
                                      return Align(
                                        alignment: Alignment.center,
                                        child: FractionallySizedBox(
                                          widthFactor: 0.80,
                                          child: CourseCard(
                                            key: ValueKey(course['courseId']),
                                            course: course,
                                            onTeacherNameChanged: (
                                              newTeacherName,
                                            ) {
                                              final idx = _allCourses
                                                  .indexWhere(
                                                    (c) =>
                                                        c['courseId'] ==
                                                        course['courseId'],
                                                  );
                                              if (idx != -1) {
                                                setState(() {
                                                  _allCourses[idx] = {
                                                    ..._allCourses[idx],
                                                    'teacherName':
                                                        newTeacherName,
                                                  };
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
              ),
              // ボトムナビ
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CommonBottomNavigation(
                  onNavigate: (page) {
                    ref.read(currentPageProvider.notifier).state = page;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 教員名を更新するメソッド
  void _updateTeacherName(String courseId, String newTeacherName) {
    setState(() {
      for (int i = 0; i < _allCourses.length; i++) {
        if (_allCourses[i]['courseId'] == courseId) {
          _allCourses[i] = {..._allCourses[i], 'teacherName': newTeacherName};
          break;
        }
      }
    });
    print('Updated teacher name for $courseId to: $newTeacherName');
  }

  Widget _buildSearchAndFilterUI() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 検索バー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '講義名や教員名で検索...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                        : null,
              ),
              onChanged: (text) {
                _applyFilters();
              },
            ),
          ),
          const SizedBox(height: 10),
          // フィルタードロップダウン
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  '学部で絞り込む',
                  _selectedFaculty,
                  _faculties,
                  (String? newValue) {
                    setState(() {
                      _selectedFaculty = newValue;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFilterDropdown('タグで絞り込む', _selectedTag, _tags, (
                  String? newValue,
                ) {
                  setState(() {
                    _selectedTag = newValue;
                  });
                  _applyFilters();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String hintText,
    String? selectedValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue ?? '',
          hint: Text(hintText, style: TextStyle(color: Colors.grey[700])),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          onChanged: (val) {
            if (val == '') {
              onChanged(null); // 選択解除
            } else {
              onChanged(val);
            }
          },
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(
                '選択解除',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            DropdownMenuItem<String>(
              enabled: false,
              child: Divider(color: Colors.grey[400], height: 1),
            ),
            ...items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _DummyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  _DummyHeaderDelegate({required this.height});
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
