import 'package:flutter/material.dart';

class ReviewPost extends StatelessWidget {
  const ReviewPost({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.edit),
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => const ReviewDialog(),
        );
      },
    );
  }
}

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key});

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  double examDifficulty = 3;
  double classDifficulty = 3;
  String comment = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'レビュー投稿',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('試験難易度（1:易しい〜5:難しい）'),
                Slider(
                  value: examDifficulty,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: examDifficulty.toString(),
                  onChanged: (value) => setState(() => examDifficulty = value),
                ),
                const SizedBox(height: 8),
                const Text('授業難易度（1:易しい〜5:難しい）'),
                Slider(
                  value: classDifficulty,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: classDifficulty.toString(),
                  onChanged: (value) => setState(() => classDifficulty = value),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'コメント'),
                  maxLines: 3,
                  onChanged: (value) => setState(() => comment = value),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // ここで保存処理
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('レビューを投稿しました')),
                          );
                        }
                      },
                      child: const Text('投稿'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
