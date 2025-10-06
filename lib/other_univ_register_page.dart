import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'character_question_page.dart';

class OtherUnivRegisterPage extends StatefulWidget {
  final String selectedUniversity;
  const OtherUnivRegisterPage({Key? key, required this.selectedUniversity})
    : super(key: key);

  @override
  State<OtherUnivRegisterPage> createState() => _OtherUnivRegisterPageState();
}

class _OtherUnivRegisterPageState extends State<OtherUnivRegisterPage> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  String? _error;
  bool _agree = false;
  bool _loading = false;
  bool _obscure = true;

  static const accent = Color(0xFF2E6DB6);

  Future<void> _register() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pw.text.trim(),
      );

      if (cred.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'universityType': 'other',
              'universityName': widget.selectedUniversity,
              'profileCompleted': false,
            }, SetOptions(merge: true));

        await cred.user!.sendEmailVerification();
        if (!mounted) return;
        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('仮登録完了'),
                content: const Text('認証メールを送信しました。リンクをクリックして本登録を完了してください。'),
                actions: [
                  TextButton(
                    onPressed:
                        () async => await cred.user!.sendEmailVerification(),
                    child: const Text('再送信', style: TextStyle(color: accent)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await cred.user!.reload();
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && user.emailVerified) {
                        if (mounted) Navigator.of(context).pop();
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => CharacterQuestionPage(),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('まだ認証が完了していません')),
                          );
                        }
                      }
                    },
                    child: const Text('次へ', style: TextStyle(color: accent)),
                  ),
                ],
              ),
        );
      }
    } on FirebaseAuthException catch (e) {
      var msg = e.message ?? e.code;
      if (e.code == 'email-already-in-use') {
        msg = 'このメールアドレスは既に登録されています';
      }
      if (mounted) setState(() => _error = msg);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: accent,
        centerTitle: true,
        elevation: 0,
        title: Text('アカウント作成（${widget.selectedUniversity}）'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const SizedBox(height: 8),
            Text(
              'メール認証後に本登録が完了します',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _input('メールアドレス', Icons.alternate_email),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pw,
              obscureText: _obscure,
              decoration: _input(
                'パスワード',
                Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _agree,
                  activeColor: accent,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                ),
                const Text('利用規約に同意する'),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _agree && !_loading ? _register : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: accent.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                    _loading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          '登録',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: accent, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }
}
