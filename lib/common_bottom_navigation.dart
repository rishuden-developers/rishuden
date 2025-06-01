// lib/common_bottom_navigation.dart
import 'package:flutter/material.dart';

// 各ページを識別するためのenum
enum AppPage { park, timetable, creditReview, ranking, item }

class CommonBottomNavigation extends StatelessWidget {
  final AppPage currentPage;
  final VoidCallback? onParkTap;
  final VoidCallback? onTimetableTap;
  final VoidCallback? onCreditReviewTap;
  final VoidCallback? onRankingTap;
  final VoidCallback? onItemTap;

  // 各ボタンには「通常状態」の画像パスを指定
  final String parkIconAsset;
  final String timetableIconAsset;
  final String creditReviewIconAsset;
  final String rankingIconAsset;
  final String itemIconAsset;

  const CommonBottomNavigation({
    super.key,
    required this.currentPage,
    this.onParkTap,
    this.onTimetableTap,
    this.onCreditReviewTap,
    this.onRankingTap,
    this.onItemTap,
    required this.parkIconAsset,
    required this.timetableIconAsset,
    required this.creditReviewIconAsset,
    required this.rankingIconAsset,
    required this.itemIconAsset,
  });

  // lib/common_bottom_navigation.dart 内の CommonBottomNavigation クラス

  Widget _buildNavItem({
    required String iconAssetPath,
    required AppPage page,
    required VoidCallback? onPressed,
    required double buttonWidth, // ボタン全体の幅
    required double buttonHeight, // ボタン全体の高さ
    required bool isActive,
  }) {
    // ★★★ アイコン自体の表示サイズを調整 ★★★
    // ボタンの高さに対して、より大きな割合をアイコン表示に使う
    final double iconDisplayProportion = 0.80; // 例: ボタンの高さの80%をアイコン基本サイズに
    final double iconDisplaySize = buttonHeight * iconDisplayProportion;

    Widget iconImage = Image.asset(
      iconAssetPath,
      width: iconDisplaySize,
      height: iconDisplaySize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print(
          "Error loading image $iconAssetPath (isActive: $isActive): $error",
        );
        return Icon(
          Icons.broken_image,
          size: iconDisplaySize * 0.8,
          color: Colors.grey[400],
        );
      },
    );

    // アクティブな場合にアイコンを拡大
    Widget finalIconContent =
        isActive
            ? Transform.scale(
              scale: 1.15, // ★ 基本サイズが大きくなったので、拡大率を少し調整 (例: 1.3 → 1.15)
              alignment: Alignment.center,
              child: iconImage,
            )
            : iconImage; // 非アクティブ時は iconDisplaySize で表示される

    return Expanded(
      child: InkWell(
        onTap: isActive ? null : onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
          decoration:
              isActive
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.amber[600]!, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber[400]!.withOpacity(0.7),
                        blurRadius: 7.0,
                        spreadRadius: 1.0,
                      ),
                      BoxShadow(
                        color: Colors.yellowAccent[200]!.withOpacity(0.4),
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  )
                  : null,
          alignment: Alignment.center,
          child: Opacity(
            opacity: isActive ? 1.0 : 0.75, // ★ 非アクティブ時の透明度を少し上げる (0.65 → 0.75)
            child: finalIconContent,
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) { ... } の部分は変更ありません。
  // ただし、navButtonHeight (例: 60.0) と、BottomAppBar の子の Container の height
  // (例: navButtonHeight + 15) が、新しいアイコンサイズに対して十分なスペースを
  // 提供できているか、見た目を確認して必要であれば調整してください。

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double navButtonWidth = screenWidth * 0.18;
    final double navButtonHeight = 60.0;

    return BottomAppBar(
      color: Colors.transparent, // 背景を透明に (ページ背景が見えるように)
      elevation: 0, // 影もなし
      padding: EdgeInsets.zero,
      child: Container(
        height: navButtonHeight + 15, // バー全体の高さ (アイコンの拡大やエフェクトを考慮)
        // decoration: BoxDecoration( // ボタンバー自体に背景をつけたい場合はここを有効化
        //    color: Colors.black.withOpacity(0.2),
        // ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _buildNavItem(
              iconAssetPath: creditReviewIconAsset,
              page: AppPage.creditReview,
              onPressed: onCreditReviewTap,
              buttonWidth: navButtonWidth,
              buttonHeight: navButtonHeight,
              isActive: currentPage == AppPage.creditReview,
            ),
            _buildNavItem(
              iconAssetPath: rankingIconAsset,
              page: AppPage.ranking,
              onPressed: onRankingTap,
              buttonWidth: navButtonWidth,
              buttonHeight: navButtonHeight,
              isActive: currentPage == AppPage.ranking,
            ),
            _buildNavItem(
              iconAssetPath: parkIconAsset,
              page: AppPage.park,
              onPressed: onParkTap,
              buttonWidth: navButtonWidth,
              buttonHeight: navButtonHeight,
              isActive: currentPage == AppPage.park,
            ),
            _buildNavItem(
              iconAssetPath: itemIconAsset,
              page: AppPage.item,
              onPressed: onItemTap,
              buttonWidth: navButtonWidth,
              buttonHeight: navButtonHeight,
              isActive: currentPage == AppPage.item,
            ),
            _buildNavItem(
              iconAssetPath: timetableIconAsset,
              page: AppPage.timetable,
              onPressed: onTimetableTap,
              buttonWidth: navButtonWidth,
              buttonHeight: navButtonHeight,
              isActive: currentPage == AppPage.timetable,
            ),
          ],
        ),
      ),
    );
  } // build メソッドの閉じ括弧
} // ★★★ CommonBottomNavigation クラスの閉じ括弧 ★★★
