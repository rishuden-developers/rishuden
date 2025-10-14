import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingLottie extends StatelessWidget {
  const LoadingLottie({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/loading.json', // ← pubspec.yaml と一致させる
      width: size,
      height: size,
      repeat: true,
      animate: true,
      fit: BoxFit.contain,
    );
  }
}
