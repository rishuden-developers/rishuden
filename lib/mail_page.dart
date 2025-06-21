import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class MailPage extends StatefulWidget {
  const MailPage({super.key});

  @override
  State<MailPage> createState() => _MailPageState();
}

class _MailPageState extends State<MailPage> {
  final TextEditingController _controller = TextEditingController();
  bool _sent = false;

  final List<String> _characterImages = [
    'assets/character_swordman.png',
    'assets/character_wizard.png',
    'assets/character_gorilla.png',
    'assets/character_merchant.png',
    'assets/character_adventurer.png',
    'assets/character_god.png',
    'assets/character_takuji.png',
  ];

  late final String _thankYouCharacter;

  @override
  void initState() {
    super.initState();
    _thankYouCharacter =
        _characterImages[Random().nextInt(_characterImages.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();

    await FirebaseFirestore.instance.collection('feedback').add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _sent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'ご意見ありがとうございます！運営ギルドに伝書を送りました。',
          style: TextStyle(fontFamily: 'misaki', color: Colors.white),
        ),
        backgroundColor: Colors.black.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // 背景
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/ranking_guild_background.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
            ),
          ),

          // キャラクター配置（左右＋上）
          Positioned(
            left: screenWidth * 0.03,
            bottom: screenHeight * 0.1,
            child: Transform.rotate(
              angle: -0.2,
              child: Image.asset(
                'assets/character_adventurer.png',
                height: screenHeight * 0.25,
              ),
            ),
          ),
          Positioned(
            right: screenWidth * 0.03,
            bottom: screenHeight * 0.4,
            child: Transform.rotate(
              angle: 0.15,
              child: Image.asset(
                'assets/character_wizard.png',
                height: screenHeight * 0.22,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.07, // 位置を調整して見切れ防止
            right: screenWidth * 0.15,
            child: Transform.rotate(
              angle: -0.1,
              child: Image.asset(
                'assets/character_god.png',
                height: screenHeight * 0.18,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.22,
            left: screenWidth * 0.04,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: '戻る',
            ),
          ),

          // タイトル（おしゃれな上部表示）
          Positioned(
            top: screenHeight * 0.22,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white70, width: 1.2),
                ),
                child: const Text(
                  '運営ギルドへの伝書',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'misaki',
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black45, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 本体ビュー（フォーム or サンクス）
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child:
                  _sent
                      ? _buildThankYouView(screenWidth, screenHeight)
                      : _buildFormView(screenWidth, screenHeight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      key: const ValueKey('FormView'),
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          width: min(480, screenWidth * 0.88),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ご意見・ご要望・不具合報告などをお寄せください！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.4,
                  fontFamily: 'misaki',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 8,
                  style: const TextStyle(
                    fontFamily: 'misaki',
                    fontSize: 15,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: '（例）こんな機能が欲しい、このキャラが好き…など',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: 'misaki',
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed:
                    _controller.text.trim().isEmpty ? null : _sendFeedback,
                icon: const Icon(Icons.send, size: 18, color: Colors.white),
                label: const Text('伝書を送る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'misaki',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '※ 匿名で送信されます。',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThankYouView(double screenWidth, double screenHeight) {
    return Container(
      key: const ValueKey('ThankYouView'),
      width: min(480, screenWidth * 0.85),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.brown[50]?.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _thankYouCharacter,
            height: screenHeight * 0.2,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            '伝書、確かに受け取りました！',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'misaki',
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ご意見は運営ギルドへ届けられました。\nご協力ありがとうございました！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'misaki',
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              textStyle: const TextStyle(
                fontFamily: 'misaki',
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
