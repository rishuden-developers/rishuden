import 'package:flutter/material.dart';
import 'dart:math';

/// 科目パターンから一意の色を生成するユーティリティクラス
class CourseColorGenerator {
  /// 科目名から一意の色を生成
  ///
  /// 同じ科目名は常に同じ色を返し、異なる科目名は異なる色を返します。
  static Color generateColor(String subjectName) {
    // 科目名のハッシュ値を計算
    int hash = subjectName.hashCode;

    // ハッシュ値から色の成分を生成
    Random random = Random(hash);

    // 明るすぎず暗すぎない色を生成
    int r = 100 + random.nextInt(155); // 100-255
    int g = 100 + random.nextInt(155); // 100-255
    int b = 100 + random.nextInt(155); // 100-255

    return Color.fromARGB(255, r, g, b);
  }

  /// 科目名と教室の組み合わせから一意の色を生成
  ///
  /// 同じ科目名と教室の組み合わせは常に同じ色を返します。
  static Color generateColorWithClassroom(
    String subjectName,
    String classroom,
  ) {
    String combined = '$subjectName|$classroom';
    return generateColor(combined);
  }

  /// 科目パターンから一意の色を生成
  static Color generateColorFromPattern(String courseId) {
    return generateColor(courseId);
  }
}
