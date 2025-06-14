import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MailPage extends StatefulWidget {
  const MailPage({super.key});

  @override
  State<MailPage> createState() => _MailPageState();
}

class _MailPageState extends State<MailPage> {
  final TextEditingController _controller = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await FirebaseFirestore.instance.collection('feedback').add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お問い合わせ・ご意見')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child:
              _sent
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'ご協力ありがとうございます！\nあなたの声がこのアプリを進化させます。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ご意見・ご要望をお聞かせください！',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'このアプリはユーザーのフィードバックを元に進化します。\nどんな小さなことでも、ぜひあなたの声をお聞かせください！',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _controller,
                        minLines: 5,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText: 'ご意見・ご要望・バグ報告など何でもどうぞ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed:
                            _controller.text.trim().isEmpty
                                ? null
                                : _sendFeedback,
                        icon: const Icon(Icons.send),
                        label: const Text('送信'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '※ 匿名で送信されます。個人情報は含めないでください。',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
