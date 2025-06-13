import 'package:flutter/material.dart';
import 'dart:ui';

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
    const double activeSize = 80.0;
    const double inactiveSize = 60.0;
    const double activeYOffset = -8.0;
    const double inactiveYOffset = 8.0;

    final double currentSize = isActive ? activeSize : inactiveSize;
    final double currentYOffset = isActive ? activeYOffset : inactiveYOffset;
    final String photoToShow = isActive ? activeIconAsset : inactiveIconAsset;

    return Expanded(
      child: InkWell(
        onTap: isActive ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, currentYOffset, 0),
          transformAlignment: Alignment.center,
          child: Image.asset(
            photoToShow,
            width: currentSize,
            height: currentSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.broken_image,
                size: currentSize * 0.8,
                color: Colors.grey[400],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double barHeight = 95.0;

    return SizedBox(
      height: barHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // 背景画像（ファイル名は後で変更）
          Positioned.fill(
            child: Image.asset('assets/bottom_bar_bg.png', fit: BoxFit.cover),
          ),
          // ボタン群
          Row(
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
        ],
      ),
    );
  }
}
