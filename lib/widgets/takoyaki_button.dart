import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TakoyakiButton extends StatefulWidget {
  final String? userId;
  final String reviewId;
  const TakoyakiButton({super.key, this.userId, required this.reviewId});

  @override
  State<TakoyakiButton> createState() => _TakoyakiButtonState();
}

class _TakoyakiButtonState extends State<TakoyakiButton> {
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _checkIfSent();
  }

  Future<void> _checkIfSent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sent =
          prefs.getBool('takoyaki_sent_${widget.reviewId}_${user.uid}') ??
          false;
    });
  }

  Future<void> _sendTakoyaki() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'takoyakiCount': FieldValue.increment(1)});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('notifications')
        .add({
      'type': 'takoyaki_received',
      'senderId': user.uid,
      'reason': 'あなたのレビュー',
      'reviewId': widget.reviewId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('takoyaki_sent_${widget.reviewId}_${user.uid}', true);

    if (!mounted) return;
    setState(() {
      _sent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'たこ焼きを送りました！',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _sent ? null : _sendTakoyaki,
      icon: Image.asset('assets/takoyaki.png', width: 24, height: 24),
      label: Text(
        _sent ? '送信済み' : '有益！たこ焼き',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _sent ? Colors.grey : Colors.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}