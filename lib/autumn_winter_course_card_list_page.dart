import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'credit_review_page.dart';
import 'autumn_winter_review_input_page.dart';
import 'autumn_winter_course_review_page.dart';
import 'providers/timetable_provider.dart';
import 'common_bottom_navigation.dart'; // ボトムナビゲーション用
import 'main_page.dart';
import 'providers/current_page_provider.dart';
import 'credit_input_page.dart' show tagOptions;
import 'providers/background_image_provider.dart';

class AutumnWinterCourseCardListPage extends ConsumerStatefulWidget {
  const AutumnWinterCourseCardListPage({super.key});

  @override
  ConsumerState<AutumnWinterCourseCardListPage> createState() =>
      _AutumnWinterCourseCardListPageState();
}

class _AutumnWinterCourseCardListPageState
    extends ConsumerState<AutumnWinterCourseCardListPage> {
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _pagedCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;
  static const int pageSize = 20;
  int _currentPage = 1;
  PageController _pageController = PageController();

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
    _loadAllCourses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCourses() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('course_data').get();
      final List<Map<String, dynamic>> allCourses = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null &&
            data.containsKey('data') &&
            data['data'] is Map &&
            (data['data'] as Map)['courses'] is List) {
          final List<dynamic> courseList = (data['data'] as Map)['courses'];
          for (final course in courseList) {
            if (course is Map<String, dynamic>) {
              final lectureName = course['lectureName'] ?? course['name'] ?? '';
              final teacherName =
                  course['teacherName'] ??
                  course['instructor'] ??
                  course['teacher'] ??
                  '';
              final classroom = course['classroom'] ?? course['room'] ?? '';
              final category = course['category'] ?? '';
              final semester = course['semester'] ?? '';
              String finalTeacherName = teacherName;
              if (lectureName.isNotEmpty) {
                final timetableTeacherName =
                    ref.read(timetableProvider)['teacherNames']?[lectureName];
                if (timetableTeacherName != null &&
                    timetableTeacherName.isNotEmpty) {
                  finalTeacherName = timetableTeacherName;
                }
              }
              allCourses.add({
                'lectureName': lectureName,
                'teacherName': finalTeacherName,
                'classroom': classroom,
                'category': category,
                'semester': semester,
                'avgSatisfaction': 0.0,
                'avgEasiness': 0.0,
                'reviewCount': 0,
                'hasMyReview': false,
              });
            }
          }
        }
      }

      // 秋冬学期用: 授業名・教員名でレビュー情報を取得
      await _loadReviewStatsForAutumnWinter(allCourses);

      setState(() {
        _allCourses = allCourses;
        _filteredCourses = allCourses;
        _currentPage = 1;
        _pagedCourses = _getPagedCourses(1);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading autumn/winter courses: $e');
      setState(() => _isLoading = false);
    }
  }

  // 秋冬学期用: 授業名・教員名でレビュー統計を取得
  Future<void> _loadReviewStatsForAutumnWinter(
    List<Map<String, dynamic>> courses,
  ) async {
    for (int i = 0; i < courses.length; i++) {
      final lectureName = courses[i]['lectureName'];
      final teacherName = courses[i]['teacherName'];

      if (lectureName.isNotEmpty && teacherName.isNotEmpty) {
        try {
          // 授業名と教員名でレビューを検索
          final reviewsSnapshot =
              await FirebaseFirestore.instance
                  .collection('reviews')
                  .where('lectureName', isEqualTo: lectureName)
                  .where('teacherName', isEqualTo: teacherName)
                  .get();

          final reviews = reviewsSnapshot.docs;
          if (reviews.isNotEmpty) {
            double totalSatisfaction = 0.0;
            double totalEasiness = 0.0;
            bool hasMyReview = false;
            final user = FirebaseAuth.instance.currentUser;

            for (final doc in reviews) {
              final data = doc.data();
              final satisfaction = (data['overallSatisfaction'] ?? 0.0) * 1.0;
              final easiness = (data['easiness'] ?? 0.0) * 1.0;

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
          print('Error fetching reviews for $lectureName - $teacherName: $e');
        }
      }
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

      // その学部のユーザーがレビューを投稿している授業のlectureNameとteacherNameを取得
      final reviewsSnapshot =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('userId', whereIn: userIds)
              .get();

      final reviewedLectures =
          reviewsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'lectureName': data['lectureName'] ?? '',
              'teacherName': data['teacherName'] ?? '',
            };
          }).toSet();

      // 該当する授業のみを返す
      return courses.where((course) {
        final lectureName = course['lectureName'] ?? '';
        final teacherName = course['teacherName'] ?? '';
        return reviewedLectures.any(
          (review) =>
              review['lectureName'] == lectureName &&
              review['teacherName'] == teacherName,
        );
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

      final reviewedLectures =
          reviewsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'lectureName': data['lectureName'] ?? '',
              'teacherName': data['teacherName'] ?? '',
            };
          }).toSet();

      // 該当する授業のみを返す
      return courses.where((course) {
        final lectureName = course['lectureName'] ?? '';
        final teacherName = course['teacherName'] ?? '';
        return reviewedLectures.any(
          (review) =>
              review['lectureName'] == lectureName &&
              review['teacherName'] == teacherName,
        );
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
                  title: const Text('秋冬学期の授業一覧'),
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
              // 横スクロールページビュー
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
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      80,
                                    ),
                                    itemCount: paged.length,
                                    itemBuilder: (context, index) {
                                      return Align(
                                        alignment: Alignment.center,
                                        child: FractionallySizedBox(
                                          widthFactor: 0.80,
                                          child: Card(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            elevation: 5,
                                            color: Colors.white,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AutumnWinterCourseReviewPage(
                                                          lectureName:
                                                              paged[index]['lectureName'],
                                                          teacherName:
                                                              paged[index]['teacherName'],
                                                        ),
                                                  ),
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      paged[index]['lectureName'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if ((paged[index]['classroom'] ??
                                                            '')
                                                        .isNotEmpty)
                                                      Text(
                                                        '教室: ${paged[index]['classroom']}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '教員: ',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            (paged[index]['teacherName'] ??
                                                                        '')
                                                                    .isNotEmpty
                                                                ? paged[index]['teacherName']
                                                                : '未設定',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  (paged[index]['teacherName'] ??
                                                                              '')
                                                                          .isNotEmpty
                                                                      ? Colors
                                                                          .black
                                                                      : Colors
                                                                          .grey[500],
                                                              fontStyle:
                                                                  (paged[index]['teacherName'] ??
                                                                              '')
                                                                          .isEmpty
                                                                      ? FontStyle
                                                                          .italic
                                                                      : FontStyle
                                                                          .normal,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              color:
                                                                  Colors.amber,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${(paged[index]['avgSatisfaction'] ?? 0.0).toStringAsFixed(1)}',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .amber,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .sentiment_satisfied,
                                                              color:
                                                                  Colors.green,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${(paged[index]['avgEasiness'] ?? 0.0).toStringAsFixed(1)}',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.rate_review,
                                                              color:
                                                                  Colors.blue,
                                                              size: 16,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${paged[index]['reviewCount'] ?? 0}件',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        Colors
                                                                            .blue,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
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
