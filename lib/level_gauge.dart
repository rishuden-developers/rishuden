import 'package:flutter/material.dart';
import 'dart:async';

class LiquidLevelGauge extends StatefulWidget {
  final double width;
  final double height;
  final Function(int currentExp, int currentLevel, int expForNextLevel)?
  onExpChanged;

  const LiquidLevelGauge({
    super.key,
    required this.width,
    required this.height,
    this.onExpChanged,
  });

  @override
  State<LiquidLevelGauge> createState() => LiquidLevelGaugeState();
}

class LiquidLevelGaugeState extends State<LiquidLevelGauge> {
  // --- ステータス変数 ---
  int _currentLevel = 1;
  int _currentExp = 0;
  int _expForNextLevel = 100;

  bool _showExpGainedText = false;
  Timer? _expGainedTimer;
  bool _isLevelingUp = false;
  bool _isFillingUp = false;

  // --- 見た目の定義 ---
  final List<Color> liquidGradient = const [
    Color(0xFF00FFFF), // 蛍光シアン (Aqua)
    Color(0xFF00BFFF), // 少し濃い青 (DeepSkyBlue)
  ];
  final TextStyle levelTextStyle = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontFamily: 'NotoSansJP',
    shadows: [
      Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1)),
    ],
  );

  @override
  void dispose() {
    _expGainedTimer?.cancel();
    super.dispose();
  }

  void addExperience(int amount) async {
    _expGainedTimer?.cancel();
    setState(() {
      _showExpGainedText = true;
    });
    _expGainedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted)
        setState(() {
          _showExpGainedText = false;
        });
    });

    final int newExp = _currentExp + amount;

    if (newExp < _expForNextLevel) {
      setState(() {
        _currentExp = newExp;
      });
      // Firebaseに保存
      _saveToFirebase();
    } else {
      final int oldExpForNextLevel = _expForNextLevel;
      setState(() {
        _isFillingUp = true;
        _currentExp = oldExpForNextLevel;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      setState(() {
        _isLevelingUp = true;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      setState(() {
        _currentLevel++;
        _currentExp = newExp - oldExpForNextLevel;
        _expForNextLevel = (_expForNextLevel * 1.5).round();
        _isLevelingUp = false;
        _isFillingUp = false;
      });
      // Firebaseに保存
      _saveToFirebase();
    }
  }

  // ★★★ Firebaseに保存するメソッド ★★★
  void _saveToFirebase() {
    // コールバック関数が設定されている場合は呼び出し
    if (widget.onExpChanged != null) {
      widget.onExpChanged!(_currentExp, _currentLevel, _expForNextLevel);
    }
  }

  // ★★★ FirebaseからEXPとレベルデータを読み込むメソッド ★★★
  void loadFromFirebase(int currentExp, int currentLevel, int expForNextLevel) {
    if (mounted) {
      setState(() {
        _currentExp = currentExp;
        _currentLevel = currentLevel;
        _expForNextLevel = expForNextLevel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
        _expForNextLevel > 0
            ? (_currentExp / _expForNextLevel).clamp(0.0, 1.0)
            : 0;
    final double widgetWidth = widget.width;
    final double widgetHeight = widget.height;
    final double gaugeInnerWidth = widgetWidth * 0.89;

    final liquidCore = AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: gaugeInnerWidth * progress,
      decoration: BoxDecoration(
        // ★ constを削除
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FFFF).withOpacity(0.2), // 開始：薄いシアン
            const Color(0xFF00FFFF).withOpacity(0.6), // 中間：濃いめのシアン
            const Color.fromARGB(255, 153, 36, 221).withOpacity(1.0), // 終了：パープル
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // ★★★ 光沢感（boxShadow）を追加 ★★★
        boxShadow: [
          // 1層目: グラデーションの色に合わせた内側の光
          BoxShadow(
            color: const Color(0xFF00FFFF).withOpacity(0.5), // 明るい水色の光
            blurRadius: 12.0,
            spreadRadius: 3.0,
          ),
          // 2層目: 外側に大きく広がる白い光
          BoxShadow(
            color: Colors.white.withOpacity(0.45),
            blurRadius: 50.0,
            spreadRadius: 40.0,
          ),
        ],
      ),
    );

    return SizedBox(
      width: widgetWidth,
      height: widgetHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/ui_level_hp_bg.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.fill,
          ),

          Padding(
            padding: EdgeInsets.only(
              left: widgetWidth * 0.055,
              right: widgetWidth * 0.055,
              top: widgetHeight * 0.34,
              bottom: widgetHeight * 0.25,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widgetHeight * 0.5),
              // ★★★ AnimatedCrossFadeの内部構造を修正 ★★★
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 150),
                crossFadeState:
                    _isFillingUp
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,

                // layoutBuilderは不要になりました

                // 通常時のゲージ（斜め断面）
                firstChild: Container(
                  alignment: Alignment.centerLeft, // 強制的に左揃え
                  child: ClipPath(clipper: SlantedClipper(), child: liquidCore),
                ),

                // 満タン時のゲージ（丸い端）
                secondChild: Container(
                  alignment: Alignment.centerLeft, // こちらも強制的に左揃え
                  child: liquidCore,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedOpacity(
              opacity: _showExpGainedText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Text(
                  '+20 EXP',
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 4,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: widgetWidth * 0.32,
              height: widgetHeight,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow:
                    _isLevelingUp
                        ? [
                          BoxShadow(
                            color: Colors.yellowAccent.withOpacity(0.7),
                            blurRadius: 20.0,
                            spreadRadius: 8.0,
                          ),
                        ]
                        : [],
              ),
              alignment: Alignment(0.0, 0.3),
              child: Text.rich(
                TextSpan(
                  style: levelTextStyle,
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Lv.',
                      style: TextStyle(fontSize: widgetHeight * 0.25),
                    ),
                    TextSpan(
                      text: '$_currentLevel',
                      style: TextStyle(fontSize: widgetHeight * 0.45),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SlantedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    final double slantAmount = size.height * 0.8;
    path.lineTo(size.width - slantAmount, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
