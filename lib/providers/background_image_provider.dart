import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBackgroundImagePathKey = 'background_image_path';
const defaultBackgroundImage = 'assets/night_view.png';

final backgroundImagePathProvider =
    StateNotifierProvider<BackgroundImagePathNotifier, String>(
      (ref) => BackgroundImagePathNotifier(),
    );

class BackgroundImagePathNotifier extends StateNotifier<String> {
  BackgroundImagePathNotifier() : super(defaultBackgroundImage) {
    loadBackgroundImagePath();
  }

  Future<void> loadBackgroundImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kBackgroundImagePathKey);
    if (path != null && path.isNotEmpty) {
      state = path;
    } else {
      state = defaultBackgroundImage;
    }
  }

  Future<void> setBackgroundImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBackgroundImagePathKey, path);
    state = path;
  }

  Future<void> resetBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBackgroundImagePathKey);
    state = defaultBackgroundImage;
  }
}
