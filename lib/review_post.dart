import 'package:flutter/material.dart';

class ReviewPost extends StatelessWidget {
  const ReviewPost({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.edit),
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
  double satisfaction = 3;
  double ease = 3;
  String examType = 'レポート';
  String attendance = '自由';
  List<String> teacherTraits = [];
  String classFormat = '対面';
  String comment = '';

  final List<String> examOptions = ['レポート', '筆記', '出席点'];
  final List<String> attendanceOptions = ['自由', '毎回点呼', '出席点あり'];
  final List<String> traitsOptions = ['優しい', '厳しい', 'おもしろい', '聞き取りにくい'];
  final List<String> classFormats = ['対面', 'オンデマンド', 'Zoom'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'レビュー投稿',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('総合満足度'),
              Slider(
                value: satisfaction,
                min: 1,
                max: 5,
                divisions: 4,
                label: satisfaction.toString(),
                onChanged: (value) => setState(() => satisfaction = value),
              ),
              const Text('楽単度'),
              Slider(
                value: ease,
                min: 1,
                max: 5,
                divisions: 4,
                label: ease.toString(),
                onChanged: (value) => setState(() => ease = value),
              ),
              const SizedBox(height: 8),
              const Text('試験の形式'),
              DropdownButtonFormField<String>(
                value: examType,
                items: examOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => examType = value!),
              ),
              const SizedBox(height: 8),
              const Text('出席の厳しさ'),
              DropdownButtonFormField<String>(
                value: attendance,
                items: attendanceOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => attendance = value!),
              ),
              const SizedBox(height: 8),
              const Text('教員の特徴'),
              Wrap(
                spacing: 8,
                children: traitsOptions.map((trait) {
                  return FilterChip(
                    label: Text(trait),
                    selected: teacherTraits.contains(trait),
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? teacherTraits.add(trait)
                            : teacherTraits.remove(trait);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              const Text('講義の形式'),
              DropdownButtonFormField<String>(
                value: classFormat,
                items: classFormats
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => classFormat = value!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'おすすめコメント'),
                maxLines: 4,
                onChanged: (value) => comment = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'コメントを入力してください';
                  }
                  return null;
                },
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
                        // ここに保存処理やAPI呼び出しを実装
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
    );
  }
}
