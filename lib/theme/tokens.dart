import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // Only for Colors.transparent

/// iOSライクな配色/タイポ/スペーシングのトークン集約
/// - Light/DarkはMediaQuery/CupertinoThemeのbrightnessで自動切替
class AppTokens {
  AppTokens._();

  // Spacing
  static const double spaceXs = 6;
  static const double spaceSm = 10;
  static const double spaceMd = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 28;

  // Radius
  static const double radiusM = 12;
  static const double radiusL = 16;

  // Durations
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration durationNormal = Duration(milliseconds: 200);

  // Easing
  static const Curve curveFastOut = Curves.easeOutCubic;
  static const Curve curveNormal = Curves.easeInOut;

  // Colors (Light/Dark対応)
  static AppColors colorsOf(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.maybeOf(context)?.platformBrightness ??
        Brightness.light;
    final isDark = brightness == Brightness.dark;
    return isDark ? AppColors.dark() : AppColors.light();
  }

  // TextStyles（デフォルトでSF相当。色は後段で上書き）
  static TextStyle title20(BuildContext context) =>
      CupertinoTheme.of(context).textTheme.navTitleTextStyle.merge(
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      );

  static TextStyle title17(BuildContext context) =>
      CupertinoTheme.of(context).textTheme.textStyle.merge(
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      );

  static TextStyle body17(BuildContext context) =>
      CupertinoTheme.of(context).textTheme.textStyle.merge(
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.25),
      );

  static TextStyle caption13(BuildContext context) =>
      CupertinoTheme.of(context).textTheme.textStyle.merge(
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.25),
      );

  // Hairline divider（iOS風の極薄ライン）
  static Widget insetDivider(BuildContext context, {EdgeInsetsGeometry? margin}) {
    final c = colorsOf(context);
    return Container(
      height: 0.5,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      color: c.divider,
    );
  }

  // ナビバー下のボーダーを消したい時に使用
  static Border get transparentBottomBorder => const Border(
        bottom: BorderSide(color: Colors.transparent, width: 0),
      );
}

class AppColors {
  final Color bg;
  final Color secondaryBg;
  final Color label;
  final Color secondaryLabel;
  final Color tint; // iOS Blue
  final Color divider;

  const AppColors({
    required this.bg,
    required this.secondaryBg,
    required this.label,
    required this.secondaryLabel,
    required this.tint,
    required this.divider,
  });

  factory AppColors.light() => const AppColors(
        bg: Color(0xFFFFFFFF),
        secondaryBg: Color(0xFFF2F2F7), // secondarySystemBackground
        label: Color(0xFF000000),
        secondaryLabel: Color(0xFF6C6C70),
        tint: Color(0xFF0A84FF),
        divider: Color(0x1F000000), // 約12%の黒: 極薄
      );

  factory AppColors.dark() => const AppColors(
        bg: Color(0xFF000000),
        secondaryBg: Color(0xFF1C1C1E),
        label: Color(0xFFFFFFFF),
        secondaryLabel: Color(0xFF98989F),
        tint: Color(0xFF0A84FF),
        divider: Color(0x33FFFFFF), // 約20%の白: 極薄
      );
}
