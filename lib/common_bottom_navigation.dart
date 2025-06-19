import 'package:flutter/material.dart';
import 'dart:ui'; // BackdropFilter のために必要

enum AppPage { park, timetable, creditReview, ranking, item }

class CommonBottomNavigation extends StatelessWidget {
  final AppPage currentPage;
  final VoidCallback? onParkTap;
  final VoidCallback? onTimetableTap;
  final VoidCallback? onCreditReviewTap;
  final VoidCallback? onRankingTap;
  final VoidCallback? onItemTap;

  final String parkIconAsset;
  final String parkIconActiveAsset;
  final String timetableIconAsset;
  final String timetableIconActiveAsset;
  final String creditReviewIconAsset;
  final String creditReviewActiveAsset;
  final String rankingIconAsset;
  final String rankingIconActiveAsset;
  final String itemIconAsset;
  final String itemIconActiveAsset;

  const CommonBottomNavigation({
    super.key,
    required this.currentPage,
    this.onParkTap,
    this.onTimetableTap,
    this.onCreditReviewTap,
    this.onRankingTap,
    this.onItemTap,
    required this.parkIconAsset,
    required this.parkIconActiveAsset,
    required this.timetableIconAsset,
    required this.timetableIconActiveAsset,
    required this.creditReviewIconAsset,
    required this.creditReviewActiveAsset,
    required this.rankingIconAsset,
    required this.rankingIconActiveAsset,
    required this.itemIconAsset,
    required this.itemIconActiveAsset,
  });

  Widget _buildNavItem({
    required String inactiveIconAsset,
    required String activeIconAsset,
    required VoidCallback? onPressed,
    required bool isActive,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Image.asset(
                  isActive ? activeIconAsset : inactiveIconAsset,
                  width: 28, // アイコンのサイズを調整
                  height: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  _getLabelForAsset(inactiveIconAsset),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[400],
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLabelForAsset(String assetPath) {
    if (assetPath.contains('park')) return '公園';
    if (assetPath.contains('timetable')) return '時間割';
    if (assetPath.contains('review')) return '履修レビュー';
    if (assetPath.contains('ranking')) return 'ランキング';
    if (assetPath.contains('item')) return 'アイテム';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // ここでぼかしを適用
        child: Container(
          decoration: BoxDecoration(
            color: Colors.indigo[800]!.withOpacity(0.8), // 半透明の背景色
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _buildNavItem(
                  inactiveIconAsset: rankingIconAsset,
                  activeIconAsset: rankingIconActiveAsset,
                  onPressed: onRankingTap,
                  isActive: currentPage == AppPage.ranking,
                ),
                _buildNavItem(
                  inactiveIconAsset: creditReviewIconAsset,
                  activeIconAsset: creditReviewActiveAsset,
                  onPressed: onCreditReviewTap,
                  isActive: currentPage == AppPage.creditReview,
                ),
                _buildNavItem(
                  inactiveIconAsset: parkIconAsset,
                  activeIconAsset: parkIconActiveAsset,
                  onPressed: onParkTap,
                  isActive: currentPage == AppPage.park,
                ),
                _buildNavItem(
                  inactiveIconAsset: timetableIconAsset,
                  activeIconAsset: timetableIconActiveAsset,
                  onPressed: onTimetableTap,
                  isActive: currentPage == AppPage.timetable,
                ),
                _buildNavItem(
                  inactiveIconAsset: itemIconAsset,
                  activeIconAsset: itemIconActiveAsset,
                  onPressed: onItemTap,
                  isActive: currentPage == AppPage.item,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  }
  