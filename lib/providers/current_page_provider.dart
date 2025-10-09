import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppPage { ranking, credit, park, timetable, dress }

// 現在のページ番号を管理するプロバイダー
final currentPageProvider = StateProvider<AppPage>((ref) => AppPage.park);
