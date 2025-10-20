import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 画像から時間割を入力するためのUI（画像解析は別のpythonスクリプトを想定）
class ImageTimetableInputUI extends StatefulWidget {
  const ImageTimetableInputUI({Key? key}) : super(key: key);

  @override
  State<ImageTimetableInputUI> createState() => _ImageTimetableInputUIState();
}

class _ImageTimetableInputUIState extends State<ImageTimetableInputUI> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      _pickedImage = x;
    });
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x == null) return;
    setState(() {
      _pickedImage = x;
    });
  }

  void _confirm() {
    if (_pickedImage == null) {
      // 画像が選択されていない場合は警告を出す
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像が選択されていません。画像を選択してください。')),
      );
      return;
    }

    // UIの役割はここで選択した画像パスを返すこと。
    // 画像解析は別のプロセス/スクリプトで行う前提のため、Navigatorでパスを返す。
    Navigator.of(context).pop(_pickedImage!.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像で時間割を入力'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '画像で時間割を入力する場合はこちらから選択してください（実験用UI）。\n※ 画像解析は別ファイルで行います。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // 画像選択ボタン群
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('ギャラリー'),
                    onPressed: _pickFromGallery,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('カメラ'),
                    onPressed: _pickFromCamera,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 画像プレビュー領域
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedImage == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.image, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('ここに選択した画像が表示されます', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_pickedImage!.path),
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // 確定ボタン
            ElevatedButton(
              onPressed: _confirm,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text('確定', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),

            // キャンセル
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
